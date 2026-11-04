package game
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;

	public class Hero extends Entity
	{
		// static = belongs to the class, not each hero. Hero.SIZE from anywhere
		public static const SIZE:Number = 40;

		private var sword:Sprite;
		private var combo:Combo;

		// current swing. angles are relative to where the hero faces
		private var swingFrom:Number;
		private var swingTo:Number;
		private var swingTime:int;
		private var swingStart:int;

		public function Hero()
		{
			super(4, SIZE / 2); // 4 px per frame, 240 px/sec at 60fps

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
				removeEventListener(Event.ENTER_FRAME, onSwingFrame); // forget this and it runs forever
				return;
			}
			sword.rotation = swingFrom + (swingTo - swingFrom) * t; // lerp
		}

		private function onComboReset(e:ComboEvent):void
		{
			// remove is safe even if the listener isnt there anymore
			removeEventListener(Event.ENTER_FRAME, onSwingFrame);
			sword.rotation = 0;
			sword.scaleX = 1;
			dispatchEvent(e);
		}
	}
}
