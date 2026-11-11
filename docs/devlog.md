## Day 1, November 1 2026

Today was mostly about understanding what actually happens between my .as files and a running game. I came in thinking mxmlc used the JVM to run my code and that some swf compiler then ran the game. That was wrong. The JVM only runs the compiler, the .swf it produces holds ABC bytecode, and AVM2 inside the AIR runtime is what runs it. That clicked once I compared it to C# with IL and the CLR.

Then I did the Lesson 1 exercise. Main now draws a blue 40 by 40 hero square in the middle of the screen, adds a thin gray sword as a child of the hero, and rotates the hero 45 degrees so the sword rotates with it. It compiled on the first try into a 949 byte swf.

What broke was running it. ADL closed instantly with exit code 3, no window and no trace output. Exit code 3 means ADL cannot find the runtime, so I looked inside the SDK, and the win and win64 runtime folders only had a placeholder file called sentinel. Then the AIR SDK Manager showed me a second copy of the SDK in OneDrive, broken the other way around: it had the Windows runtime but no adl or mxmlc in its bin folder. Neither copy could do both jobs.

I moved the broken copy out of the SDK folder so the manager stopped detecting it, reinstalled 51.5.1 from the manager, and pointed VS Code at the fresh install. It printed Hello AIR and confirmed the sword's parent is the hero. Then I deleted the leftover copies.

I also had the SDK path in my VS Code settings written with backslashes, which is invalid in JSON. Forward slashes fixed it.

Tomorrow is Lesson 2, the game loop and keyboard input.

## Day 2, November 2 2026

Today the hero started moving. The goal was WASD and arrow keys, smooth movement in eight directions, and no way to walk out of the window.

Before writing anything I had to fix my picture of what a Sprite is. Making one with new Sprite only creates an object in memory. Nothing draws it until it is added with addChild to something that is already on the stage. And the sword is not a property of the hero, it is a child in the hero's display list, which is why it follows the hero around.

The first new thing was that the stage is null inside the Main constructor. Main is not on the display list yet when the constructor runs, so I moved all the setup into an init function that only runs once the ADDED_TO_STAGE event fires, or right away if the stage already exists.

Then the game loop. AS3 has no update method to override, so I listen for ENTER_FRAME, which fires once per frame, 60 times a second for me. The keyboard listeners go on the stage, because only the focused object gets key events and the stage sees all of them. KEY_DOWN and KEY_UP just write true or false into an object keyed by the key code, and the loop reads that map every frame.

Pressing two directions at once gives a vector of length about 1.41, so diagonals were going to be around 41 percent faster. I divide by the length to normalize it. After moving, I clamp the position with Math.max and Math.min so the square stays inside 960 by 540, and I point the hero toward where it walks with atan2, converted from radians to degrees.

It compiled on the first try into a 1314 byte swf.

## Day 3, November 3 2026

Today was about getting code out of Main. After yesterday everything lived in one file, the drawing, the keys and the movement, and Main was already 112 lines. The goal was a Hero class in its own package, an Input class for the keys, and Main only wiring things together.

I made a game folder inside src, and every file in it starts with package game. Main imports game.Hero and game.Input to use them, like a using in C#.

Input got the key map and the three stage listeners straight from Main. It is not a Sprite, just a normal class that receives the stage in its constructor. I added two getters, moveX and moveY, that return minus 1, 0 or 1, so the hero does not care if I use WASD or the arrows.

For the hero I went one step further and made an Entity base class that extends Sprite, because enemies are coming and they will also need a size, a speed and a way to stay on screen. Hero extends Entity, calls super with its speed and half size, and overrides draw to make the square and the sword. In AS3 the override keyword is required, leaving it out is a compile error and not just a warning like in C#. Speed is now a getter and setter over a private variable, so hero.speed reads like a field but can never go negative. The hero size is a static const, so it lives on the class instead of on each hero.

Main is shorter and the heroe moves like he used to, it worked.

Honestly it was pretty easy. It is the same thing I saw in my first year of university in Programacion 1, dividing the code into classes and using abstraction, just in a new language.

## Day 4, November 4 2026

Today the hero got its attack. The goal was a three hit combo where tapping attack chains three different swings, and waiting too long drops it back to the start.

I built the combo as a state machine in its own class called Combo, with five states: idle, attack 1, attack 2, attack 3 and recovery. Each swing has a length in milliseconds, and after hit 1 or hit 2 ends there is a 350 millisecond window to press again. Pressing during a swing queues the next hit, so it does not get lost. If the window runs out the combo resets, and after hit 3 there is a 400 millisecond recovery where presses are ignored. All the timing uses getTimer, which returns milliseconds since the app started.

Combo extends EventDispatcher instead of Sprite, because it never goes on screen and only needs to dispatch events. I wrote my own event class, ComboEvent, with a HIT type, a RESET type and the hit number. The Hero listens to the combo and passes the events up to Main, which for now only traces them.

For the visuals, the sword now sits at the center of the hero so rotating it swings it around him. Hit 1 swings left to right, hit 2 comes back right to left, and hit 3 is a full spin with a longer sword. The hero adds an ENTER_FRAME listener when a swing starts and removes it when the swing ends. While attacking he moves slower and stops turning.

The attack key is J or Space. KEY_DOWN repeats while a key is held, so Input only counts the first one, and holding the key does not chain the combo by itself.

It compiled into a 4320 byte swf.

## Day 5, November 5 2026

Today the hero got something to hit. The goal was an enemy that chases him, a sword that only hurts while it is swinging, damage with knockback, and an enemy that dies at 0 HP.

The enemy is a red square that extends Entity, just like Hero. Every frame it walks straight at the hero at half his speed. HP and knockback went into Entity, since both of them need it. A hit lowers the HP and pushes the entity away from where the hit came from, and that push shrinks a little every frame. While an enemy is sliding back it cannot chase me or hurt me.

The sword was the interesting part. The blade is a child of the hero and rotates around him, so its position on screen depends on the sword rotation, the hero rotation and the scale of the spin. I keep four points along the blade in the sword's own coordinates and convert them with localToGlobal, and Flash does all that math for me. Then I check if any point is inside the enemy box. The sword is only active while a swing is moving, and each enemy can only get hit once per swing, otherwise one slash would hit it every frame.

For the enemy touching me I compare two rectangles with intersects. I did not use getBounds or hitTestObject on the hero, because his bounds include the sword, so an enemy touching the blade would count as touching me. After a hit the hero blinks and cannot be hurt again for 800 milliseconds.

The full combo does 4 damage and the enemy has 5 HP. When it dies it gets removed and a new one spawns a second later.

It compiled into a 6915 byte swf.

## Day 6, November 6 2026

Today the one red square became three kinds of enemies. The goal was two or three enemy types without copy pasting the enemy code, and making sure dead enemies are really gone and not just invisible.

First I had to set the project up again, because I am on a Mac now. Same steps as day one, the JDK, the AIR SDK 51.5.1 for macOS and the two VS Code extensions. This time I checked the runtimes folder before anything else, and the mac runtime was there. The settings.json in the repo still pointed at my Windows SDK folder, so I changed it to the new path, and since Homebrew does not put Java on the PATH I gave the extension the java path in my user settings. The old code compiled and ADL opened the window on the first try.

Enemy is now a base class with everything the enemies share: the HP bar, the knockback, the contact damage and an update function marked final, so no subclass can replace it and forget the knockback part. Update calls a protected think function that is empty in Enemy, and each type overrides it with its own AI. The color is a getter that each subclass overrides, because static constants are not virtual and Enemy could never see Charger's color.

The Chaser is the day 5 enemy, and its class is now just a constructor and a two line think. The Charger walks slowly, and when I get close it stops, blinks white and shows a faint line where it is going to dash, then dashes in a straight line and stands there for a moment, which is the time to punish it. The direction is locked when the warning starts, otherwise it would be impossible to dodge. Hitting it cancels the charge. The Shooter keeps its distance, lights up for a moment and shoots a yellow bullet at me every 1.6 seconds. It does not create the bullet itself, it dispatches a ShotEvent and Main makes the Projectile, so Main owns every bullet and its cleanup.

The bullet is not an Entity, it has no HP and no knockback, but it hurts me on touch just like an enemy. That is where an interface made sense. IHarmful has a hit box, canHurt and contactDamage, Enemy and Projectile both implement it, and Main has one touchHero function that works for both. Base class where there is code to share, interface where two unrelated things only need to answer the same questions.

Main keeps the enemies in a Vector of Enemy and the bullets in a Vector of Projectile, and spawns waves of one of each, plus an extra Chaser every two waves. The loops that remove things go backwards, because removing index i while going forward shifts the next enemy into i and the loop skips it.

Then the cleanup. Killing an enemy now removes the listener Main put on it, calls destroy, which takes it off the display list and removes its own listeners, and takes it out of the Vector. To check that it actually worked I put every dead enemy in a Dictionary with weak keys, which does not count as a reference, forced a garbage collection with System.gc between waves and counted what was still in there. The first thing it caught was in the Hero, not the enemies. The list of enemies already hit by the current swing was only cleared when the next swing started, so the enemy I had just killed stayed in memory until I attacked again. Now it is cleared as soon as the swing ends.

I also tested what really happens with a listener nobody removes. I removed a Charger in the middle of its warning, with only removeChild, and it survived 30 forced garbage collections, with its blinking code still running every frame even though it was off the screen. A plain Sprite with an ENTER_FRAME listener, on the other hand, was freed on the first one, so it is not as simple as the old tutorials say. I am not relying on luck, every listener I add gets removed.

After that fix I cleared five waves in a row and the leak check said zero every time.

It compiled into a 10453 byte swf.

## Day 7, November 7 2026

Today the game got a dungeon. The goal was a Room with walls, enemy spawns and doors, where the doors unlock when every enemy is dead and walking through one loads the next room.

I did not want to place walls with a hundred drawRect calls, so a room is a text map. Each room is an array of 18 strings of 32 characters, and every character is a 30 pixel tile, so it is exactly 960 by 540. A hash is a wall, a dot is floor, D is a door, H is where the hero starts, and c, r and s are a chaser, a charger and a shooter. The three maps live in RoomMaps, and I can see the room just by looking at the code. The Room constructor reads the map with charAt, builds a Rectangle for every wall and door, remembers the spawns, and throws an Error if a row has the wrong length or there is no H.

The spawns store the class itself. In AS3 a Class is a normal value, so I keep the Chaser class in an object under the letter c and later do var type:Class = s.type and new type(). It is like Activator.CreateInstance in C#. Adding a new enemy to the maps is one more line in that object.

The walls were the hard part. The hero and the enemies move first and then Room.collide pushes them out of whatever they ended up inside. It does x first and then y, and each time it looks at which side they came from. Doing the axes separately means that walking diagonally into a wall slides along it and does not stop dead. The shooter bullets die when they touch a wall, and a locked door counts as a wall until the room is cleared.

The doors are red with bars while locked. When the last enemy dies Main tells the room to unlock, the doors turn green and let me through, and touching one loads the next room. After the third room it goes back to the first one.

Main needed one change I did not expect. Before, enemies were added at index 0 to stay under the hero, but now the room has to be under everything. So I made three Sprites as layers, room, enemies and bullets, added in that order, and everything goes into its layer. The hero is added after them so it is on top.

The cleanup from yesterday works the same way. Loading a room removes the old one from its layer, and I put it in the weak Dictionary next to the dead enemies. The check printed zero after clearing the second room, so the first room was freed too.

I checked the three maps with a small script, because a room I cannot beat is a bug. It looks for a path of 40 pixels wide, the size of the hero, from the start to the door, and checks that every enemy is reachable and none spawns inside a wall. All three pass. A test of Room on its own also passes: it pushes the hero out of a wall, slides him along it, blocks him at a locked door and lets him through an open one.

I could not fully play it with a bot. It cleared two rooms in a row and walked through the door into the next one, but the shooter keeps its distance and the bot never got past it in room 3 in time. Room 3 needs to be played by hand.

It compiled into a 13244 byte swf.
