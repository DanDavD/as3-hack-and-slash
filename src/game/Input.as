package game
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;

	// not a Sprite, doesnt need to be on screen. just a normal class
	public class Input
	{
		// keyCode -> true while held. basically a Dictionary<int, bool>
		private var keys:Object = {};

		public function Input(stage:Stage)
		{
			// still on the stage, it gets every key no matter what has focus
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			// alt tab while holding a key = KEY_UP never comes, so clear everything
			stage.addEventListener(Event.DEACTIVATE, onDeactivate);
		}

		public function isDown(code:uint):Boolean
		{
			return keys[code] == true; // missing key = undefined, == true makes it false
		}

		// -1, 0 or 1. getters so the hero can just read input.moveX
		public function get moveX():Number
		{
			var dx:Number = 0;
			if (isDown(Keyboard.A) || isDown(Keyboard.LEFT)) dx -= 1;
			if (isDown(Keyboard.D) || isDown(Keyboard.RIGHT)) dx += 1;
			return dx;
		}

		// y goes DOWN in flash, so up is -1
		public function get moveY():Number
		{
			var dy:Number = 0;
			if (isDown(Keyboard.W) || isDown(Keyboard.UP)) dy -= 1;
			if (isDown(Keyboard.S) || isDown(Keyboard.DOWN)) dy += 1;
			return dy;
		}

		private function onKeyDown(e:KeyboardEvent):void
		{
			keys[e.keyCode] = true;
		}

		private function onKeyUp(e:KeyboardEvent):void
		{
			keys[e.keyCode] = false;
		}

		private function onDeactivate(e:Event):void
		{
			keys = {};
		}
	}
}
