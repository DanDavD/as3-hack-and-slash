package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;

	// sets the window size, fps and bg color. same [ ] thing as attributes in C#
	[SWF(width="960", height="540", frameRate="60", backgroundColor="#1a1a22")]
	public class Main extends Sprite
	{
		private const HERO_SPEED:Number = 4; // px per frame, so 240 px/sec at 60fps
		private const HERO_HALF:Number = 20; // half the square, for the screen edges

		private var hero:Sprite;
		private var sword:Sprite;

		// keyCode -> true while held. basically a Dictionary<int, bool>
		private var keys:Object = {};

		// constructor = where the game starts, basically my main()
		public function Main()
		{
			// stage is null in here!! main isnt on the display list yet,
			// so wait for ADDED_TO_STAGE before touching it
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		// e = null so i can also call it directly with no event
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);

			// hero square. drawing from -20,-20 so the origin is in the middle,
			// otherwise it rotates around the top left corner
			hero = new Sprite();
			hero.graphics.beginFill(0x3366FF);
			hero.graphics.drawRect(-HERO_HALF, -HERO_HALF, HERO_HALF * 2, HERO_HALF * 2);
			hero.graphics.endFill();
			hero.x = stage.stageWidth / 2;
			hero.y = stage.stageHeight / 2;
			addChild(hero); // not on screen until its in the display list!!

			// sword is a child of hero -> x = 24 is from the hero's center, not the screen
			sword = new Sprite();
			sword.graphics.beginFill(0x999999);
			sword.graphics.drawRect(0, -3, 30, 6);
			sword.graphics.endFill();
			sword.x = 24;
			hero.addChild(sword);

			// keys go on the stage, not on main or the hero
			// (only the focused object gets key events, stage gets everything)
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			// alt tab while holding a key = KEY_UP never comes, so just clear everything
			stage.addEventListener(Event.DEACTIVATE, onDeactivate);

			// the game loop. runs once per frame (60 times a sec)
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
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

		private function isDown(code:uint):Boolean
		{
			return keys[code] == true; // missing key = undefined, so == true makes it false
		}

		private function onEnterFrame(e:Event):void
		{
			// -1, 0 or 1 on each axis. y goes DOWN in flash, so up is -1
			var dx:Number = 0;
			var dy:Number = 0;
			if (isDown(Keyboard.A) || isDown(Keyboard.LEFT)) dx -= 1;
			if (isDown(Keyboard.D) || isDown(Keyboard.RIGHT)) dx += 1;
			if (isDown(Keyboard.W) || isDown(Keyboard.UP)) dy -= 1;
			if (isDown(Keyboard.S) || isDown(Keyboard.DOWN)) dy += 1;

			if (dx == 0 && dy == 0) return; // not moving, nothing to do

			// diagonal would be (1,1) = length 1.41, so ~41% faster. normalize it
			var len:Number = Math.sqrt(dx * dx + dy * dy);
			dx /= len;
			dy /= len;

			hero.x += dx * HERO_SPEED;
			hero.y += dy * HERO_SPEED;

			// clamp so the square stays in the window. sword can poke out, whatever
			hero.x = Math.max(HERO_HALF, Math.min(stage.stageWidth - HERO_HALF, hero.x));
			hero.y = Math.max(HERO_HALF, Math.min(stage.stageHeight - HERO_HALF, hero.y));

			// face where im walking. atan2 gives radians, rotation wants degrees
			hero.rotation = Math.atan2(dy, dx) * 180 / Math.PI;
		}
	}
}
