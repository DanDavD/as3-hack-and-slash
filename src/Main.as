package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	import game.ComboEvent;
	import game.Enemy;
	import game.Hero;  // game folder = game package
	import game.Input;

	// sets the window size, fps and bg color. same [ ] thing as attributes in C#
	[SWF(width="960", height="540", frameRate="60", backgroundColor="#1a1a22")]
	public class Main extends Sprite
	{
		private static const RESPAWN_TIME:int = 1000; // ms until a new enemy shows up
		private static const CONTACT_DAMAGE:int = 1;
		private static const CONTACT_KNOCKBACK:Number = 10;

		private var input:Input;
		private var hero:Hero;
		private var enemy:Enemy; // null while dead / waiting to respawn
		private var respawnAt:int = 0;
		private var hud:Sprite; // hero hp bar, top left

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

			// hero passes its combo events up, main just listens. no idea how the combo works inside
			hero.addEventListener(ComboEvent.HIT, onHeroHit);
			hero.addEventListener(ComboEvent.RESET, onHeroComboReset);

			hud = new Sprite();
			hud.x = 16;
			hud.y = 16;
			addChild(hud); // added last = drawn on top of everything

			spawnEnemy();

			// the game loop
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function onEnterFrame(e:Event):void
		{
			hero.update(input);

			if (enemy != null)
			{
				enemy.update(hero);
				checkHits();
			}
			else if (getTimer() >= respawnAt)
			{
				spawnEnemy();
			}

			drawHud();
		}

		private function checkHits():void
		{
			// me hitting the enemy. hero knows where the blade is, main decides what happens
			if (hero.swordHits(enemy))
			{
				var died:Boolean = enemy.hurt(hero.swingDamage, hero.x, hero.y, hero.swingKnockback);
				trace("enemy hp " + enemy.hp);
				if (died)
				{
					killEnemy();
					return; // enemy is null now!!
				}
			}

			// enemy touching me. Rectangle.intersects = do the two boxes overlap at all
			if (enemy.canHurt && hero.hitBox.intersects(enemy.hitBox))
			{
				if (hero.hurt(CONTACT_DAMAGE, enemy.x, enemy.y, CONTACT_KNOCKBACK))
				{
					trace("hero died");
					hero.revive();
					hero.x = stage.stageWidth / 2;
					hero.y = stage.stageHeight / 2;
				}
			}
		}

		private function spawnEnemy():void
		{
			enemy = new Enemy();
			// opposite side from the hero so it doesnt spawn on top of me
			enemy.x = hero.x < stage.stageWidth / 2 ? stage.stageWidth - 60 : 60;
			enemy.y = 60 + Math.random() * (stage.stageHeight - 120);
			addChildAt(enemy, 0); // index 0 = bottom, so it walks under the hero
		}

		private function killEnemy():void
		{
			trace("enemy died");
			removeChild(enemy); // off the display list = gone from the screen
			enemy = null;       // and now the GC can have it (no listeners on it so nothing holds it)
			respawnAt = getTimer() + RESPAWN_TIME;
		}

		// redrawing every frame is lazy but its 2 rects, whatever
		private function drawHud():void
		{
			var w:Number = 150;
			hud.graphics.clear();
			hud.graphics.beginFill(0x000000);
			hud.graphics.drawRect(0, 0, w, 12);
			hud.graphics.endFill();
			hud.graphics.beginFill(0x33CC33);
			hud.graphics.drawRect(0, 0, w * hero.hp / hero.maxHp, 12);
			hud.graphics.endFill();
		}

		// just traces for now (F5 only)
		private function onHeroHit(e:ComboEvent):void
		{
			trace("hit " + e.hit);
		}

		private function onHeroComboReset(e:ComboEvent):void
		{
			trace("combo reset after hit " + e.hit);
		}
	}
}
