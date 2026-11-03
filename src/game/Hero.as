package game
{
	import flash.display.Sprite;

	public class Hero extends Entity
	{
		// static = belongs to the class, not each hero. Hero.SIZE from anywhere
		public static const SIZE:Number = 40;

		private var sword:Sprite;

		public function Hero()
		{
			super(4, SIZE / 2); // 4 px per frame, 240 px/sec at 60fps
		}

		// override is required in as3, compiler errors without it (C# would only warn)
		override protected function draw():void
		{
			// drawing from -half so the origin is in the middle and it rotates around the center
			graphics.beginFill(0x3366FF);
			graphics.drawRect(-halfSize, -halfSize, halfSize * 2, halfSize * 2);
			graphics.endFill();

			// sword is a child -> x = 24 is from the hero's center, not the screen
			sword = new Sprite();
			sword.graphics.beginFill(0x999999);
			sword.graphics.drawRect(0, -3, 30, 6);
			sword.graphics.endFill();
			sword.x = 24;
			addChild(sword);
		}

		// main calls this every frame
		public function update(input:Input):void
		{
			var dx:Number = input.moveX;
			var dy:Number = input.moveY;
			if (dx == 0 && dy == 0) return; // not moving, nothing to do

			// diagonal = length 1.41, so ~41% faster. normalize it
			var len:Number = Math.sqrt(dx * dx + dy * dy);
			dx /= len;
			dy /= len;

			x += dx * speed; // goes through the getter
			y += dy * speed;
			clampToStage();

			// face where im walking. atan2 = radians, rotation = degrees
			rotation = Math.atan2(dy, dx) * 180 / Math.PI;
		}
	}
}
