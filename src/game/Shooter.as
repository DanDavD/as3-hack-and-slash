package game
{
	import flash.utils.getTimer;

	// keeps its distance and shoots. the one you have to go after
	public class Shooter extends Enemy
	{
		public static const SIZE:Number = 28;

		private static const TOO_CLOSE:Number = 200;
		private static const TOO_FAR:Number = 320;
		private static const FIRE_EVERY:int = 1600;
		private static const TELL_TIME:int = 300; // lights up before shooting

		private var nextShot:int;
		private var telling:Boolean = false;

		public function Shooter()
		{
			super(1.6, SIZE / 2, 3); // 2 hits and its gone
			nextShot = getTimer() + FIRE_EVERY; // not the second it spawns
		}

		override protected function get bodyColor():uint
		{
			return 0x9955DD; // purple
		}

		override protected function think(target:Entity):void
		{
			var dist:Number = distanceTo(target);
			if (dist < TOO_CLOSE) moveToward(target, -speed);
			else if (dist > TOO_FAR) moveToward(target, speed);

			var now:int = getTimer();

			if (!telling && now >= nextShot - TELL_TIME)
			{
				telling = true;
				drawBody(0xEECCFF);
			}

			if (now >= nextShot)
			{
				telling = false;
				drawBody(bodyColor);
				nextShot = now + FIRE_EVERY;

				// i just say i shot, main makes the bullet and cleans it up
				var dx:Number = target.x - x;
				var dy:Number = target.y - y;
				var len:Number = Math.sqrt(dx * dx + dy * dy);
				if (len < 1) return;
				dispatchEvent(new ShotEvent(ShotEvent.FIRED, x, y, dx / len, dy / len));
			}
		}

		// getting hit resets the timer, so the combo can lock it down
		override public function hurt(amount:int, fromX:Number, fromY:Number, force:Number):Boolean
		{
			telling = false;
			drawBody(bodyColor);
			nextShot = getTimer() + FIRE_EVERY;
			return super.hurt(amount, fromX, fromY, force);
		}
	}
}
