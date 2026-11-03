package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import game.Hero;  // game folder = game package
	import game.Input;

	// sets the window size, fps and bg color. same [ ] thing as attributes in C#
	[SWF(width="960", height="540", frameRate="60", backgroundColor="#1a1a22")]
	public class Main extends Sprite
	{
		private var input:Input;
		private var hero:Hero;

		// constructor = where the game starts, basically my main()
		public function Main()
		{
			// stage is null in here!! wait for ADDED_TO_STAGE
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		// main only wires stuff together now, hero does its own thing
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);

			input = new Input(stage);

			hero = new Hero();
			hero.x = stage.stageWidth / 2;
			hero.y = stage.stageHeight / 2;
			addChild(hero); // not on screen until its in the display list!!

			// the game loop
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function onEnterFrame(e:Event):void
		{
			hero.update(input);
		}
	}
}
