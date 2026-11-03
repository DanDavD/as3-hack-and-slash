package game
{
	import flash.display.Sprite;

	// base class for stuff that moves around. enemies will extend this too later
	public class Entity extends Sprite
	{
		// protected = me + subclasses, same as C#
		protected var halfSize:Number;

		// _speed bc the getter below already uses the name speed
		private var _speed:Number;

		public function Entity(speed:Number, halfSize:Number)
		{
			super(); // Sprite constructor. as3 adds it for me if i forget but i like seeing it
			_speed = speed;
			this.halfSize = halfSize;
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

		// keep the square inside the window. needs to be on the stage or stage is null
		protected function clampToStage():void
		{
			x = Math.max(halfSize, Math.min(stage.stageWidth - halfSize, x));
			y = Math.max(halfSize, Math.min(stage.stageHeight - halfSize, y));
		}
	}
}
