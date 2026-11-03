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

Main went from 112 lines to 44, and its frame loop is a single call to hero.update with the input. It compiled on the first try into a 2250 byte swf.
