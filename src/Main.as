package
{
	import flash.display.Sprite;

	// sets the window size, fps and bg color. same [ ] thing as attributes in C#
	[SWF(width="960", height="540", frameRate="60", backgroundColor="#1a1a22")]
	public class Main extends Sprite
	{
		private var hero:Sprite;
		private var sword:Sprite;

		// constructor = where the game starts, basically my main()
		public function Main()
		{
			trace("Hello, AIR"); // only shows up with F5 (debugger)

			// hero square. drawing from -20,-20 so the origin is in the middle,
			// otherwise it rotates around the top left corner
			hero = new Sprite();
			hero.graphics.beginFill(0x3366FF);
			hero.graphics.drawRect(-20, -20, 40, 40); // x, y, w, h
			hero.graphics.endFill();
			hero.x = 480; // half of 960
			hero.y = 270; // half of 540
			addChild(hero); // not on screen until its in the display list!!

			// sword is a child of hero -> x = 24 is from the hero's center, not the screen
			sword = new Sprite();
			sword.graphics.beginFill(0x999999);
			sword.graphics.drawRect(0, -3, 30, 6);
			sword.graphics.endFill();
			sword.x = 24;
			hero.addChild(sword);

			// rotate the parent and the sword should follow it
			hero.rotation = 45; // degrees, not radians

			// just checking the parent/child thing actually worked
			trace("hero children: " + hero.numChildren + ", sword parent is hero: " + (sword.parent == hero));
		}
	}
}
