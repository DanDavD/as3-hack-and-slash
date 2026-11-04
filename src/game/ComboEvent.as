package game
{
	import flash.events.Event;

	// my own event type. same idea as a custom EventArgs in C# but here the args ARE the event
	public class ComboEvent extends Event
	{
		// the type strings. consts so a typo is a compile error, not a listener that never fires
		public static const HIT:String = "comboHit";
		public static const RESET:String = "comboReset";

		// which hit, 1 2 or 3. on RESET its the last hit reached before the reset
		public var hit:int;

		public function ComboEvent(type:String, hit:int = 0)
		{
			super(type);
			this.hit = hit;
		}

		// REQUIRED if the event ever gets redispatched!! flash clones it and without this
		// the copy is a plain Event with no hit -> type error in the listener
		override public function clone():Event
		{
			return new ComboEvent(type, hit);
		}

		// just so trace(e) prints something useful
		override public function toString():String
		{
			return formatToString("ComboEvent", "type", "hit");
		}
	}
}
