package game
{
	// the day 5 enemy, just walks at you. tiny now that Enemy has everything
	public class Chaser extends Enemy
	{
		public static const SIZE:Number = 32;

		public function Chaser()
		{
			super(2, SIZE / 2, 5); // half the hero's speed so i can actually get away
		}

		override protected function think(target:Entity):void
		{
			moveToward(target, speed);
		}
	}
}
