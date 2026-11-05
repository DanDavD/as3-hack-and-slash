package game
{
	import flash.display.Sprite;
	import flash.geom.Rectangle;

	// base class for stuff that moves around. hero and enemy both extend this
	public class Entity extends Sprite
	{
		// protected = me + subclasses, same as C#
		protected var halfSize:Number;

		// _speed bc the getter below already uses the name speed
		private var _speed:Number;

		private var _hp:int;
		private var _maxHp:int;

		// knockback velocity, px per frame. shrinks every frame until its basically 0
		protected var vx:Number = 0;
		protected var vy:Number = 0;
		private static const KNOCKBACK_FRICTION:Number = 0.8;

		public function Entity(speed:Number, halfSize:Number, maxHp:int)
		{
			super(); // Sprite constructor. as3 adds it for me if i forget but i like seeing it
			_speed = speed;
			this.halfSize = halfSize;
			_maxHp = maxHp;
			_hp = maxHp;
			draw(); // calls the subclass version!! (in C++ this would call the base one)
		}

		// empty on purpose, subclasses override it. no abstract in as3 :(
		protected function draw():void
		{
		}

		// get/set = C# properties, from outside it looks like a normal var: hero.speed = 6
		public function get speed():Number
		{
			return _speed;
		}

		public function set speed(value:Number):void
		{
			_speed = Math.max(0, value); // no walking backwards lol
		}

		// no setters for hp on purpose, only hurt() and revive() can change it
		public function get hp():int
		{
			return _hp;
		}

		public function get maxHp():int
		{
			return _maxHp;
		}

		public function get isDead():Boolean
		{
			return _hp <= 0;
		}

		// just the body square, in my PARENT's coords (same space as x and y)
		// not getBounds() bc that includes children -> the hero's sword would count as his body
		// ignores rotation too, good enough for squares
		public function get hitBox():Rectangle
		{
			return new Rectangle(x - halfSize, y - halfSize, halfSize * 2, halfSize * 2);
		}

		// returns true if this hit killed it. fromX/fromY = where the hit came from, push away from there
		public function hurt(amount:int, fromX:Number, fromY:Number, force:Number):Boolean
		{
			_hp = Math.max(0, _hp - amount);

			var dx:Number = x - fromX;
			var dy:Number = y - fromY;
			var len:Number = Math.sqrt(dx * dx + dy * dy);
			if (len == 0) dx = 1; // exactly on top of each other, just push right
			else
			{
				dx /= len;
				dy /= len;
			}
			vx = dx * force;
			vy = dy * force;

			return isDead;
		}

		public function revive():void
		{
			_hp = _maxHp;
			vx = 0;
			vy = 0;
		}

		// still sliding from a hit
		public function get isKnockedBack():Boolean
		{
			return Math.abs(vx) + Math.abs(vy) > 0.5;
		}

		// call every frame. 8 * 0.8 * 0.8 ... adds up to ~40px total
		protected function applyKnockback():void
		{
			x += vx;
			y += vy;
			vx *= KNOCKBACK_FRICTION;
			vy *= KNOCKBACK_FRICTION;
		}

		// keep the square inside the window. needs to be on the stage or stage is null
		protected function clampToStage():void
		{
			x = Math.max(halfSize, Math.min(stage.stageWidth - halfSize, x));
			y = Math.max(halfSize, Math.min(stage.stageHeight - halfSize, y));
		}
	}
}
