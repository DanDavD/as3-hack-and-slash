package game
{
	import flash.display.Sprite;

	// base for every enemy. subclasses only pick a color and fill in think()
	public class Enemy extends Entity implements IHarmful
	{
		private var hpBar:Sprite;

		public function Enemy(speed:Number, halfSize:Number, maxHp:int)
		{
			super(speed, halfSize, maxHp);
		}

		// getter so subclasses can override it, a static const wouldnt work here
		protected function get bodyColor():uint
		{
			return 0xCC3333;
		}

		override protected function draw():void
		{
			drawBody(bodyColor);

			// child so it follows the enemy around. enemy never rotates so its fine here
			hpBar = new Sprite();
			hpBar.y = -halfSize - 8;
			addChild(hpBar);
			drawHpBar();
		}

		// apart from draw() so the charger can flash without touching the hp bar
		protected function drawBody(color:uint):void
		{
			graphics.clear();
			graphics.beginFill(color);
			graphics.drawRect(-halfSize, -halfSize, halfSize * 2, halfSize * 2);
			graphics.endFill();
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

		// main calls this every frame. final = nobody can override it (sealed in C#)
		public final function update(target:Entity):void
		{
			applyKnockback();

			// no thinking while flying back from a hit
			if (!isKnockedBack) think(target);

			clampToStage();
			alpha = isKnockedBack ? 0.5 : 1; // cheap "i got hit" flash
		}

		// the ai, each type does its own
		protected function think(target:Entity):void
		{
		}

		protected function distanceTo(target:Entity):Number
		{
			var dx:Number = target.x - x;
			var dy:Number = target.y - y;
			return Math.sqrt(dx * dx + dy * dy);
		}

		// negative amount = walk away
		protected function moveToward(target:Entity, amount:Number):void
		{
			var dx:Number = target.x - x;
			var dy:Number = target.y - y;
			var len:Number = Math.sqrt(dx * dx + dy * dy);
			if (len < 1) return; // already on top of him, dont divide by ~0
			x += dx / len * amount;
			y += dy / len * amount;
		}

		// stunned enemies cant hurt me, otherwise it hits back mid knockback and feels unfair
		public function get canHurt():Boolean
		{
			return !isDead && !isKnockedBack;
		}

		public function get contactDamage():int
		{
			return 1;
		}

		override public function hurt(amount:int, fromX:Number, fromY:Number, force:Number):Boolean
		{
			var died:Boolean = super.hurt(amount, fromX, fromY, force);
			drawHpBar();
			return died;
		}

		// off the screen. subclasses with their own listeners remove them here too
		public function destroy():void
		{
			if (parent != null) parent.removeChild(this);
		}
	}
}
