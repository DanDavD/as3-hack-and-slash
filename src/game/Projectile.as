package game
{
	import flash.display.Sprite;
	import flash.geom.Rectangle;

	// the shooter's bullet. not an Entity, no hp, but it still hurts like an enemy
	public class Projectile extends Sprite implements IHarmful
	{
		public static const RADIUS:Number = 6;
		public static const SPEED:Number = 5; // faster than me, dodge sideways

		private var vx:Number;
		private var vy:Number;

		public function Projectile(startX:Number, startY:Number, dirX:Number, dirY:Number)
		{
			x = startX;
			y = startY;
			vx = dirX * SPEED;
			vy = dirY * SPEED;

			graphics.beginFill(0xFFDD44);
			graphics.drawCircle(0, 0, RADIUS);
			graphics.endFill();
		}

		// main moves it, no ENTER_FRAME of its own = nothing to clean up
		public function update():void
		{
			x += vx;
			y += vy;
		}

		public function isOutside(w:Number, h:Number):Boolean
		{
			return x < -RADIUS || y < -RADIUS || x > w + RADIUS || y > h + RADIUS;
		}

		public function get hitBox():Rectangle
		{
			return new Rectangle(x - RADIUS, y - RADIUS, RADIUS * 2, RADIUS * 2);
		}

		public function get canHurt():Boolean
		{
			return true;
		}

		public function get contactDamage():int
		{
			return 1;
		}
	}
}
