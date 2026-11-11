package game
{
	import flash.events.Event;

	// a shooter fired. where from and which way
	public class ShotEvent extends Event
	{
		public static const FIRED:String = "shotFired";

		public var fromX:Number;
		public var fromY:Number;
		public var dirX:Number; // normalized
		public var dirY:Number;

		public function ShotEvent(type:String, fromX:Number, fromY:Number, dirX:Number, dirY:Number)
		{
			super(type);
			this.fromX = fromX;
			this.fromY = fromY;
			this.dirX = dirX;
			this.dirY = dirY;
		}

		// always, learned that one on day 4
		override public function clone():Event
		{
			return new ShotEvent(type, fromX, fromY, dirX, dirY);
		}

		override public function toString():String
		{
			return formatToString("ShotEvent", "type", "fromX", "fromY", "dirX", "dirY");
		}
	}
}
