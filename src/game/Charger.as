package game
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;

	// stops, blinks, shows where its going, then dashes. you see it coming
	public class Charger extends Enemy
	{
		public static const SIZE:Number = 36;

		private static const WALK:String = "walk";
		private static const WINDUP:String = "windup";
		private static const DASH:String = "dash";
		private static const REST:String = "rest";

		private static const RANGE:Number = 220;
		private static const WINDUP_TIME:int = 650; // enough to react
		private static const DASH_TIME:int = 300;
		private static const DASH_SPEED:Number = 11;
		private static const REST_TIME:int = 800;   // free hits

		private var state:String = WALK;
		private var stateStart:int = 0;

		// locked when the windup starts, if it followed me it would be undodgeable
		private var dirX:Number = 0;
		private var dirY:Number = 0;

		private var aimLine:Sprite;

		public function Charger()
		{
			super(1.2, SIZE / 2, 6);
		}

		override protected function get bodyColor():uint
		{
			return 0xE08A1E; // orange
		}

		override protected function draw():void
		{
			super.draw();

			aimLine = new Sprite();
			aimLine.graphics.lineStyle(2, 0xFF5533, 0.6);
			aimLine.graphics.moveTo(halfSize, 0);
			aimLine.graphics.lineTo(halfSize + DASH_SPEED * DASH_TIME * 60 / 1000, 0); // ~ how far the dash goes
			aimLine.visible = false;
			addChildAt(aimLine, 0); // under the body
		}

		override protected function think(target:Entity):void
		{
			var elapsed:int = getTimer() - stateStart;

			switch (state)
			{
				case WALK:
					moveToward(target, speed);
					if (distanceTo(target) < RANGE) startWindup(target);
					break;

				case WINDUP:
					if (elapsed >= WINDUP_TIME)
					{
						stopTelegraph();
						enter(DASH);
					}
					break;

				case DASH:
					x += dirX * DASH_SPEED;
					y += dirY * DASH_SPEED;
					if (elapsed >= DASH_TIME) enter(REST);
					break;

				case REST:
					if (elapsed >= REST_TIME) enter(WALK);
					break;
			}
		}

		private function enter(newState:String):void
		{
			state = newState;
			stateStart = getTimer();
		}

		private function startWindup(target:Entity):void
		{
			var dx:Number = target.x - x;
			var dy:Number = target.y - y;
			var len:Number = Math.sqrt(dx * dx + dy * dy);
			if (len < 1) return;
			dirX = dx / len;
			dirY = dy / len;

			aimLine.rotation = Math.atan2(dirY, dirX) * 180 / Math.PI;
			aimLine.visible = true;

			// same as the hero's swing, only listen while i need it
			addEventListener(Event.ENTER_FRAME, onTelegraphFrame);
			enter(WINDUP);
		}

		private function onTelegraphFrame(e:Event):void
		{
			drawBody(int(getTimer() / 70) % 2 == 0 ? 0xFFFFFF : bodyColor);
		}

		private function stopTelegraph():void
		{
			removeEventListener(Event.ENTER_FRAME, onTelegraphFrame);
			aimLine.visible = false;
			drawBody(bodyColor);
		}

		// the dash hurts more than just bumping into it
		override public function get contactDamage():int
		{
			return state == DASH ? 2 : 1;
		}

		// hitting it cancels the charge
		override public function hurt(amount:int, fromX:Number, fromY:Number, force:Number):Boolean
		{
			stopTelegraph();
			enter(REST);
			return super.hurt(amount, fromX, fromY, force);
		}

		// hurt() already does it but just in case. a dead one kept blinking off screen in my test
		override public function destroy():void
		{
			stopTelegraph();
			super.destroy();
		}
	}
}
