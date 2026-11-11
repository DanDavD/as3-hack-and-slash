package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import game.Charger;
	import game.Chaser;
	import game.ComboEvent;
	import game.Enemy;
	import game.Hero;  // game folder = game package
	import game.IHarmful;
	import game.Input;
	import game.Projectile;
	import game.Shooter;
	import game.ShotEvent;

	// sets the window size, fps and bg color. same [ ] thing as attributes in C#
	[SWF(width="960", height="540", frameRate="60", backgroundColor="#1a1a22")]
	public class Main extends Sprite
	{
		private static const WAVE_DELAY:int = 1200; // ms between clearing a wave and the next one
		private static const CONTACT_KNOCKBACK:Number = 10;

		private var input:Input;
		private var hero:Hero;
		private var hud:Sprite; // hero hp bar, top left

		// like List<Enemy> in C#, any enemy type fits
		private var enemies:Vector.<Enemy> = new Vector.<Enemy>();
		private var shots:Vector.<Projectile> = new Vector.<Projectile>();

		private var wave:int = 0;
		private var nextWaveAt:int = 0;
		private var gcAt:int = 0;

		// debug leak check. weak keys, so if a dead enemy is still in here after a gc something holds it
		private var graveyard:Dictionary = new Dictionary(true);

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

			nextWaveAt = getTimer() + 500;

			// the game loop
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function onEnterFrame(e:Event):void
		{
			hero.update(input);

			// same call for every type
			for each (var enemy:Enemy in enemies) enemy.update(hero);

			checkHits();
			updateShots();

			if (enemies.length == 0)
			{
				if (nextWaveAt == 0)
				{
					nextWaveAt = getTimer() + WAVE_DELAY;
					gcAt = getTimer() + WAVE_DELAY / 2;
				}
				else if (gcAt != 0 && getTimer() >= gcAt)
				{
					// halfway through the wait, in the same frame as the kill it didnt free anything
					System.gc(); // AIR and the debug player only
					gcAt = 0;
				}
				else if (getTimer() >= nextWaveAt) spawnWave();
			}

			drawHud();
		}

		private function checkHits():void
		{
			// backwards bc killEnemy removes from the vector, forward would skip one
			for (var i:int = enemies.length - 1; i >= 0; i--)
			{
				var enemy:Enemy = enemies[i];

				// me hitting the enemy. hero knows where the blade is, main decides what happens
				if (hero.swordHits(enemy))
				{
					if (enemy.hurt(hero.swingDamage, hero.x, hero.y, hero.swingKnockback))
					{
						killEnemy(i);
						continue; // its gone, dont check if it touches me
					}
				}

				touchHero(enemy);
			}
		}

		// enemies and bullets both, thats what IHarmful is for. true = touched me
		private function touchHero(thing:IHarmful):Boolean
		{
			if (!thing.canHurt) return false;
			var box:Rectangle = thing.hitBox;
			if (!hero.hitBox.intersects(box)) return false;

			var died:Boolean = hero.hurt(thing.contactDamage, box.x + box.width / 2, box.y + box.height / 2, CONTACT_KNOCKBACK);
			if (died)
			{
				trace("hero died");
				hero.revive();
				hero.x = stage.stageWidth / 2;
				hero.y = stage.stageHeight / 2;
			}
			return true;
		}

		private function updateShots():void
		{
			for (var i:int = shots.length - 1; i >= 0; i--)
			{
				var shot:Projectile = shots[i];
				shot.update();
				if (touchHero(shot) || shot.isOutside(stage.stageWidth, stage.stageHeight))
				{
					removeChild(shot);
					shots.removeAt(i); // no listeners on it, thats all it needs
				}
			}
		}

		private function spawnWave():void
		{
			nextWaveAt = 0;
			wave++;

			// should always be 0
			var leaked:int = 0;
			for (var key:Object in graveyard) leaked++;
			trace("wave " + wave + " | dead enemies still in memory after gc: " + leaked);

			// one of each, +1 chaser every 2 waves
			spawn(new Chaser());
			spawn(new Charger());
			spawn(new Shooter());
			for (var i:int = 1; i < wave; i += 2) spawn(new Chaser());
		}

		private function spawn(enemy:Enemy):void
		{
			// opposite side from the hero so it doesnt spawn on top of me
			enemy.x = hero.x < stage.stageWidth / 2 ? stage.stageWidth - 60 : 60;
			enemy.y = 60 + Math.random() * (stage.stageHeight - 120);
			addChildAt(enemy, 0); // index 0 = bottom, so it walks under the hero

			// only shooters dispatch it but whatever
			enemy.addEventListener(ShotEvent.FIRED, onEnemyShot);
			enemies.push(enemy);
		}

		private function onEnemyShot(e:ShotEvent):void
		{
			var shot:Projectile = new Projectile(e.fromX, e.fromY, e.dirX, e.dirY);
			addChildAt(shot, getChildIndex(hero)); // under the hero
			shots.push(shot);
		}

		// miss one of these and it stays in memory
		private function killEnemy(i:int):void
		{
			var enemy:Enemy = enemies[i];
			trace("enemy died");

			// i added it so i remove it
			enemy.removeEventListener(ShotEvent.FIRED, onEnemyShot);
			enemy.destroy();     // off the screen + its own listeners
			enemies.removeAt(i); // last reference main had

			graveyard[enemy] = true;
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
