package game
{
	import flash.display.Sprite;

	// first enemy. red square that walks straight at the hero, hurts on touch
	public class Enemy extends Entity
	{
		public static const SIZE:Number = 32;

		private var hpBar:Sprite;

		public function Enemy()
		{
			super(2, SIZE / 2, 5); // half the hero's speed so i can actually get away
		}

		override protected function draw():void
		{
			graphics.beginFill(0xCC3333);
			graphics.drawRect(-halfSize, -halfSize, halfSize * 2, halfSize * 2);
			graphics.endFill();

			// child so it follows the enemy around. enemy never rotates so its fine here
			// (on the hero it would spin with him)
			hpBar = new Sprite();
			hpBar.y = -halfSize - 8;
			addChild(hpBar);
			drawHpBar();
		}

		private function drawHpBar():void
		{
			var w:Number = halfSize * 2;
			hpBar.graphics.clear(); // otherwise it draws on top of the old one forever
			hpBar.graphics.beginFill(0x000000);
			hpBar.graphics.drawRect(-halfSize, 0, w, 4);
			hpBar.graphics.endFill();
			hpBar.graphics.beginFill(0x33CC33);
			hpBar.graphics.drawRect(-halfSize, 0, w * hp / maxHp, 4);
			hpBar.graphics.endFill();
		}

		// main calls this every frame
		public function update(target:Entity):void
		{
			applyKnockback();

			// no chasing while flying back from a hit
			if (!isKnockedBack)
			{
				var dx:Number = target.x - x;
				var dy:Number = target.y - y;
				var len:Number = Math.sqrt(dx * dx + dy * dy);
				if (len > 1) // already on top of him, dont divide by ~0
				{
					x += dx / len * speed;
					y += dy / len * speed;
				}
			}

			clampToStage();
			alpha = isKnockedBack ? 0.5 : 1; // cheap "i got hit" flash
		}

		// stunned enemies cant hurt me, otherwise it hits back mid knockback and feels unfair
		public function get canHurt():Boolean
		{
			return !isDead && !isKnockedBack;
		}

		override public function hurt(amount:int, fromX:Number, fromY:Number, force:Number):Boolean
		{
			var died:Boolean = super.hurt(amount, fromX, fromY, force);
			drawHpBar();
			return died;
		}
	}
}
