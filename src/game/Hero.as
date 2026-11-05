package game
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;

	public class Hero extends Entity
	{
		// static = belongs to the class, not each hero. Hero.SIZE from anywhere
		public static const SIZE:Number = 40;

		// after getting hit i cant get hit again for this long (ms), or one touch = dead
		public static const INVULN_TIME:int = 800;

		// points along the blade in the SWORD's own coords. blade is drawn from x 24 to 54
		// scaleX on the sword stretches these too when i convert them, so the spin reach just works
		private static const BLADE:Vector.<Point> = Vector.<Point>([
			new Point(24, 0), new Point(34, 0), new Point(44, 0), new Point(54, 0)
		]);

		private var sword:Sprite;
		private var combo:Combo;

		// current swing. angles are relative to where the hero faces
		private var swingFrom:Number;
		private var swingTo:Number;
		private var swingTime:int;
		private var swingStart:int;

		// the sword only hurts while its actually moving, not during the combo window
		private var swordActive:Boolean = false;
		// who already got hit by this swing, so one swing = one hit per enemy (not one per frame!!)
		private var hitThisSwing:Vector.<Entity> = new Vector.<Entity>();

		private var invulnUntil:int = 0;

		public function Hero()
		{
			super(4, SIZE / 2, 5); // 4 px per frame, 240 px/sec at 60fps. 5 hp

			combo = new Combo();
			combo.addEventListener(ComboEvent.HIT, onComboHit);
			combo.addEventListener(ComboEvent.RESET, onComboReset);
		}

		// override is required in as3, compiler errors without it (C# would only warn)
		override protected function draw():void
		{
			// drawing from -half so the origin is in the middle and it rotates around the center
			graphics.beginFill(0x3366FF);
			graphics.drawRect(-halfSize, -halfSize, halfSize * 2, halfSize * 2);
			graphics.endFill();

			// sword sits at the hero's center now and the rect is drawn out at 24,
			// so rotating the sword swings it AROUND the hero instead of spinning in place
			sword = new Sprite();
			sword.graphics.beginFill(0x999999);
			sword.graphics.drawRect(halfSize + 4, -3, 30, 6);
			sword.graphics.endFill();
			addChild(sword);
		}

		// main calls this every frame
		public function update(input:Input):void
		{
			combo.update(input.consumeAttack());

			applyKnockback();
			clampToStage();

			// blink while invulnerable. int(...) % 2 flips every 80ms
			if (isInvulnerable) alpha = int(getTimer() / 80) % 2 == 0 ? 0.3 : 1;
			else alpha = 1;

			var dx:Number = input.moveX;
			var dy:Number = input.moveY;
			if (dx == 0 && dy == 0) return; // not moving, nothing to do

			// diagonal = length 1.41, so ~41% faster. normalize it
			var len:Number = Math.sqrt(dx * dx + dy * dy);
			dx /= len;
			dy /= len;

			// slow while attacking so it feels like the swing has weight
			var moveSpeed:Number = combo.isAttacking ? speed * 0.4 : speed;
			x += dx * moveSpeed;
			y += dy * moveSpeed;
			clampToStage();

			// face where im walking, but not mid combo or the swings go everywhere
			// atan2 = radians, rotation = degrees
			if (!combo.isAttacking) rotation = Math.atan2(dy, dx) * 180 / Math.PI;
		}

		private function onComboHit(e:ComboEvent):void
		{
			// 3 different hits: left to right, right to left, full spin with a longer sword
			if (e.hit == 1)
			{
				swingFrom = -70;
				swingTo = 70;
				sword.scaleX = 1;
			}
			else if (e.hit == 2)
			{
				swingFrom = 70;
				swingTo = -70;
				sword.scaleX = 1;
			}
			else
			{
				swingFrom = 0;
				swingTo = 360;
				sword.scaleX = 1.5;
			}

			swingTime = Combo.SWING_TIME[e.hit];
			swingStart = getTimer();
			sword.rotation = swingFrom;

			// new swing, everyone can get hit again
			swordActive = true;
			hitThisSwing.length = 0; // clears a vector, like list.Clear()

			// only listen to frames while swinging. adding the same listener twice does nothing so its safe
			addEventListener(Event.ENTER_FRAME, onSwingFrame);

			// pass it up so main (and later the hit detection) hears about it
			// its already been dispatched once so flash uses my clone() here
			dispatchEvent(e);
		}

		private function onSwingFrame(e:Event):void
		{
			var t:Number = (getTimer() - swingStart) / swingTime; // 0 to 1
			if (t >= 1)
			{
				sword.rotation = swingTo; // stays there during the combo window
				swordActive = false;
				removeEventListener(Event.ENTER_FRAME, onSwingFrame); // forget this and it runs forever
				return;
			}
			sword.rotation = swingFrom + (swingTo - swingFrom) * t; // lerp
		}

		private function onComboReset(e:ComboEvent):void
		{
			// remove is safe even if the listener isnt there anymore
			removeEventListener(Event.ENTER_FRAME, onSwingFrame);
			swordActive = false;
			sword.rotation = 0;
			sword.scaleX = 1;
			dispatchEvent(e);
		}

		// main asks this every frame for each enemy. true = the blade is touching it right now
		public function swordHits(target:Entity):Boolean
		{
			if (!swordActive) return false;
			if (hitThisSwing.indexOf(target) != -1) return false; // already got this one

			var box:Rectangle = target.hitBox; // in target.parent coords
			for each (var p:Point in BLADE)
			{
				// sword coords -> stage coords -> enemy's parent coords
				// localToGlobal does all the rotation + scale of the sword AND the hero for me
				var global:Point = sword.localToGlobal(p);
				var local:Point = target.parent.globalToLocal(global);
				if (box.containsPoint(local))
				{
					hitThisSwing.push(target);
					return true;
				}
			}
			return false;
		}

		// spin hits harder and pushes further
		public function get swingDamage():int
		{
			return combo.hit == 3 ? 2 : 1;
		}

		public function get swingKnockback():Number
		{
			return combo.hit == 3 ? 14 : 8;
		}

		public function get isInvulnerable():Boolean
		{
			return getTimer() < invulnUntil;
		}

		// same as Entity.hurt but ignores hits while blinking
		override public function hurt(amount:int, fromX:Number, fromY:Number, force:Number):Boolean
		{
			if (isInvulnerable) return false;
			invulnUntil = getTimer() + INVULN_TIME;
			return super.hurt(amount, fromX, fromY, force);
		}

		override public function revive():void
		{
			super.revive();
			invulnUntil = getTimer() + INVULN_TIME; // dont get hit again the second i come back
		}
	}
}
