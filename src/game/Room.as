package game
{
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	// one room: walls, doors, where the enemies and the hero start
	// built from one of the text maps in RoomMaps
	public class Room extends Sprite
	{
		public static const TILE:int = 30;
		public static const COLS:int = 32;
		public static const ROWS:int = 18;

		// map letter -> enemy class. a Class is a normal value in as3, i can keep it in an object
		private static const ENEMY_TYPES:Object = { c: Chaser, r: Charger, s: Shooter };

		private var walls:Vector.<Rectangle> = new Vector.<Rectangle>();
		private var doors:Vector.<Rectangle> = new Vector.<Rectangle>();
		private var spawns:Array = []; // { type, x, y }
		private var _heroStart:Point;
		private var _locked:Boolean = true;

		private var doorLayer:Sprite; // separate so i can redraw just the doors when they open

		public function Room(map:Array)
		{
			if (map.length != ROWS) throw new Error("room map needs " + ROWS + " rows, has " + map.length);

			for (var row:int = 0; row < ROWS; row++)
			{
				var line:String = map[row];
				if (line.length != COLS) throw new Error("row " + row + " needs " + COLS + " tiles, has " + line.length);

				for (var col:int = 0; col < COLS; col++)
				{
					var ch:String = line.charAt(col);
					var tile:Rectangle = new Rectangle(col * TILE, row * TILE, TILE, TILE);
					// center of the tile, thats where things spawn
					var cx:Number = tile.x + TILE / 2;
					var cy:Number = tile.y + TILE / 2;

					if (ch == "#") walls.push(tile);
					else if (ch == "D") doors.push(tile);
					else if (ch == "H") _heroStart = new Point(cx, cy);
					else if (ENEMY_TYPES[ch] != null) spawns.push({ type: ENEMY_TYPES[ch], x: cx, y: cy });
				}
			}

			if (_heroStart == null) throw new Error("room map has no H");

			drawRoom();
			doorLayer = new Sprite();
			addChild(doorLayer);
			drawDoors();
		}

		// floor + walls never change, so draw once and let flash keep it as a bitmap
		private function drawRoom():void
		{
			graphics.beginFill(0x22222C);
			graphics.drawRect(0, 0, COLS * TILE, ROWS * TILE);
			graphics.endFill();

			for each (var wall:Rectangle in walls)
			{
				graphics.beginFill(0x55556A);
				graphics.drawRect(wall.x, wall.y, wall.width, wall.height);
				graphics.endFill();
				graphics.beginFill(0x3E3E50); // darker inside so the tiles read as blocks
				graphics.drawRect(wall.x + 3, wall.y + 3, wall.width - 6, wall.height - 6);
				graphics.endFill();
			}

			cacheAsBitmap = true; // lots of rects that never change, so flash keeps it as one bitmap
		}

		private function drawDoors():void
		{
			doorLayer.graphics.clear();
			for each (var door:Rectangle in doors)
			{
				if (_locked)
				{
					doorLayer.graphics.beginFill(0x882222);
					doorLayer.graphics.drawRect(door.x, door.y, door.width, door.height);
					doorLayer.graphics.endFill();
					doorLayer.graphics.beginFill(0x551111); // bars
					doorLayer.graphics.drawRect(door.x + 6, door.y, 4, door.height);
					doorLayer.graphics.drawRect(door.x + 20, door.y, 4, door.height);
					doorLayer.graphics.endFill();
				}
				else
				{
					doorLayer.graphics.beginFill(0x33AA55, 0.5);
					doorLayer.graphics.drawRect(door.x, door.y, door.width, door.height);
					doorLayer.graphics.endFill();
				}
			}
		}

		public function get heroStart():Point
		{
			return _heroStart.clone(); // a copy, so nobody moves my start point by accident
		}

		public function get isLocked():Boolean
		{
			return _locked;
		}

		// room makes them, main owns them after this
		public function createEnemies():Vector.<Enemy>
		{
			var list:Vector.<Enemy> = new Vector.<Enemy>();
			for each (var s:Object in spawns)
			{
				var type:Class = s.type;
				var enemy:Enemy = new type(); // like Activator.CreateInstance in C#
				enemy.x = s.x;
				enemy.y = s.y;
				list.push(enemy);
			}
			return list;
		}

		public function unlock():void
		{
			_locked = false;
			drawDoors();
		}

		// only once theyre open
		public function touchesDoor(box:Rectangle):Boolean
		{
			if (_locked) return false;
			for each (var door:Rectangle in doors)
			{
				if (box.intersects(door)) return true;
			}
			return false;
		}

		public function hitsWall(box:Rectangle):Boolean
		{
			return solidAt(box) != null;
		}

		// call after the entity moved. x first, then y, so it slides along walls instead of sticking
		public function collide(e:Entity, oldX:Number, oldY:Number):void
		{
			var newX:Number = e.x;
			var newY:Number = e.y;

			e.y = oldY;
			pushOut(e, true, oldX);
			e.y = newY;
			pushOut(e, false, oldY);
		}

		private function pushOut(e:Entity, onX:Boolean, from:Number):void
		{
			// a few tries in case it touches 2 blocks at once
			for (var tries:int = 0; tries < 4; tries++)
			{
				var box:Rectangle = e.hitBox;
				var solid:Rectangle = solidAt(box);
				if (solid == null) return;

				var half:Number = box.width / 2;
				if (onX)
				{
					// which side do i come from. didnt move = use the center
					var goingRight:Boolean = e.x != from ? e.x > from : e.x < solid.x + solid.width / 2;
					e.x = goingRight ? solid.left - half : solid.right + half;
				}
				else
				{
					var goingDown:Boolean = e.y != from ? e.y > from : e.y < solid.y + solid.height / 2;
					e.y = goingDown ? solid.top - half : solid.bottom + half;
				}
			}
		}

		// first wall (or locked door) that overlaps the box
		private function solidAt(box:Rectangle):Rectangle
		{
			for each (var wall:Rectangle in walls)
			{
				if (box.intersects(wall)) return wall;
			}
			if (_locked)
			{
				for each (var door:Rectangle in doors)
				{
					if (box.intersects(door)) return door;
				}
			}
			return null;
		}
	}
}
