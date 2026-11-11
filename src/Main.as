package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import game.ComboEvent;
	import game.Enemy;
	import game.Hero;  // game folder = game package
	import game.IHarmful;
	import game.Input;
	import game.Projectile;
	import game.Room;
	import game.RoomMaps;
	import game.ShotEvent;

	// sets the window size, fps and bg color. same [ ] thing as attributes in C#
	[SWF(width="960", height="540", frameRate="60", backgroundColor="#1a1a22")]
	public class Main extends Sprite
	{
		private static const CONTACT_KNOCKBACK:Number = 10;

		private var input:Input;
		private var hero:Hero;
		private var hud:Sprite; // hero hp bar, top left

		// layers, bottom to top. addChildAt(0) doesnt work anymore with a room under everything
		private var roomLayer:Sprite;
		private var enemyLayer:Sprite;
		private var shotLayer:Sprite;

		private var room:Room;
		private var roomIndex:int = -1;
		private var roomsCleared:int = 0;

		// like List<Enemy> in C#, any enemy type fits
		private var enemies:Vector.<Enemy> = new Vector.<Enemy>();
		private var shots:Vector.<Projectile> = new Vector.<Projectile>();

		private var gcAt:int = 0;
		private var leakCheckAt:int = 0;

		// debug leak check. weak keys, so if a dead enemy or old room is still in here after a gc something holds it
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

			roomLayer = new Sprite();
			enemyLayer = new Sprite();
			shotLayer = new Sprite();
			addChild(roomLayer);
			addChild(enemyLayer);
			addChild(shotLayer);

			hero = new Hero();
			addChild(hero); // not on screen until its in the display list!!

			// hero passes its combo events up, main just listens. no idea how the combo works inside
			hero.addEventListener(ComboEvent.HIT, onHeroHit);
			hero.addEventListener(ComboEvent.RESET, onHeroComboReset);

			hud = new Sprite();
			hud.x = 16;
			hud.y = 16;
			addChild(hud); // added last = drawn on top of everything

			loadRoom(0);

			// the game loop
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function onEnterFrame(e:Event):void
		{
			// remember where everyone was, the room needs it to push them out of walls
			var oldX:Number = hero.x;
			var oldY:Number = hero.y;
			hero.update(input);
			room.collide(hero, oldX, oldY);

			// same call for every type
			for each (var enemy:Enemy in enemies)
			{
				oldX = enemy.x;
				oldY = enemy.y;
				enemy.update(hero);
				room.collide(enemy, oldX, oldY);
			}

			checkHits();
			updateShots();

			if (enemies.length == 0 && room.isLocked) roomCleared();
			else if (!room.isLocked && room.touchesDoor(hero.hitBox))
			{
				loadRoom((roomIndex + 1) % RoomMaps.LIST.length); // after the last one, back to the first
				return; // new room, nothing else to do this frame
			}

			leakCheck();
			drawHud();
		}

		private function roomCleared():void
		{
			room.unlock();
			roomsCleared++;
			trace("room cleared (" + roomsCleared + " in a row)");

			gcAt = getTimer() + 500;
			leakCheckAt = getTimer() + 1000;
		}

		// gc a bit after the kill (same frame didnt free anything), count a bit after that
		private function leakCheck():void
		{
			if (gcAt != 0 && getTimer() >= gcAt)
			{
				System.gc(); // AIR and the debug player only
				gcAt = 0;
			}
			else if (leakCheckAt != 0 && getTimer() >= leakCheckAt)
			{
				leakCheckAt = 0;
				var leaked:int = 0;
				for (var key:Object in graveyard) leaked++;
				trace("still in memory after gc: " + leaked); // should always be 0
			}
		}

		private function loadRoom(index:int):void
		{
			// the old one goes away like a dead enemy, off the screen and no references
			if (room != null)
			{
				roomLayer.removeChild(room);
				graveyard[room] = true;
			}

			// should already be empty when the doors open, but just in case
			while (enemies.length > 0) killEnemy(enemies.length - 1);
			while (shots.length > 0) removeShot(shots.length - 1);

			roomIndex = index;
			room = new Room(RoomMaps.LIST[index]);
			roomLayer.addChild(room);

			var start:Point = room.heroStart;
			hero.x = start.x;
			hero.y = start.y;

			for each (var enemy:Enemy in room.createEnemies()) spawn(enemy);
			trace("room " + (index + 1));
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
				var start:Point = room.heroStart; // back to the room's start, enemies stay
				hero.x = start.x;
				hero.y = start.y;
			}
			return true;
		}

		private function updateShots():void
		{
			for (var i:int = shots.length - 1; i >= 0; i--)
			{
				var shot:Projectile = shots[i];
				shot.update();
				// walls eat bullets now
				if (touchHero(shot) || room.hitsWall(shot.hitBox) || shot.isOutside(stage.stageWidth, stage.stageHeight))
				{
					removeShot(i);
				}
			}
		}

		private function removeShot(i:int):void
		{
			shotLayer.removeChild(shots[i]);
			shots.removeAt(i); // no listeners on it, thats all it needs
		}

		private function spawn(enemy:Enemy):void
		{
			// position comes from the room map now
			enemyLayer.addChild(enemy);

			// only shooters dispatch it but whatever
			enemy.addEventListener(ShotEvent.FIRED, onEnemyShot);
			enemies.push(enemy);
		}

		private function onEnemyShot(e:ShotEvent):void
		{
			var shot:Projectile = new Projectile(e.fromX, e.fromY, e.dirX, e.dirY);
			shotLayer.addChild(shot);
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
