package game
{
	import flash.events.EventDispatcher;
	import flash.utils.getTimer;

	// the 3 hit combo, as a state machine. no drawing in here, hero listens and does the visuals
	// extends EventDispatcher (not Sprite) bc it only needs dispatchEvent, its never on screen
	public class Combo extends EventDispatcher
	{
		public static const IDLE:String = "idle";
		public static const ATTACK_1:String = "attack1";
		public static const ATTACK_2:String = "attack2";
		public static const ATTACK_3:String = "attack3";
		public static const RECOVERY:String = "recovery";

		// all in ms bc getTimer is ms. index = hit number, 0 is unused
		public static const SWING_TIME:Vector.<int> = Vector.<int>([0, 180, 180, 300]);
		public static const WINDOW_TIME:int = 350;   // after a swing ends, this long to press again
		public static const RECOVERY_TIME:int = 400; // cooldown after hit 3

		private var _state:String = IDLE;
		private var _hit:int = 0;
		private var stateStart:int = 0; // getTimer() when i entered the current state
		private var queued:Boolean = false; // pressed during a swing -> next hit as soon as it ends

		public function get state():String
		{
			return _state;
		}

		public function get hit():int
		{
			return _hit;
		}

		// window + recovery count too, so the hero stays slow until the combo is really over
		public function get isAttacking():Boolean
		{
			return _state != IDLE;
		}

		// hero calls this every frame
		public function update(attackPressed:Boolean):void
		{
			var now:int = getTimer(); // ms since the app started
			var elapsed:int = now - stateStart;

			// pressing during recovery does nothing, otherwise you could spam through it
			if (attackPressed && _state != RECOVERY) queued = true;

			switch (_state)
			{
				case IDLE:
					if (queued) startHit(1, now);
					break;

				// no break between these two, same as C (C# wouldnt let me do this with code in it)
				case ATTACK_1:
				case ATTACK_2:
					if (elapsed < SWING_TIME[_hit]) break; // still swinging
					if (queued) startHit(_hit + 1, now);
					else if (elapsed > SWING_TIME[_hit] + WINDOW_TIME) reset(now); // waited too long
					break;

				case ATTACK_3:
					if (elapsed >= SWING_TIME[3]) enter(RECOVERY, now);
					break;

				case RECOVERY:
					if (elapsed >= RECOVERY_TIME) reset(now);
					break;
			}
		}

		private function startHit(n:int, now:int):void
		{
			_hit = n;
			if (n == 1) enter(ATTACK_1, now);
			else if (n == 2) enter(ATTACK_2, now);
			else enter(ATTACK_3, now);

			dispatchEvent(new ComboEvent(ComboEvent.HIT, n));
		}

		private function reset(now:int):void
		{
			var last:int = _hit;
			_hit = 0;
			enter(IDLE, now);
			dispatchEvent(new ComboEvent(ComboEvent.RESET, last));
		}

		// every state change goes through here so the timer and the queue never get out of sync
		private function enter(newState:String, now:int):void
		{
			_state = newState;
			stateStart = now;
			queued = false;
		}
	}
}
