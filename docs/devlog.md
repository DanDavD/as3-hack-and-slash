## Day 1, November 1 2026

Today was mostly about understanding what actually happens between my .as files and a running game. I came in thinking mxmlc used the JVM to run my code and that some swf compiler then ran the game. That was wrong. The JVM only runs the compiler, the .swf it produces holds ABC bytecode, and AVM2 inside the AIR runtime is what runs it. That clicked once I compared it to C# with IL and the CLR.

Then I did the Lesson 1 exercise. Main now draws a blue 40 by 40 hero square in the middle of the screen, adds a thin gray sword as a child of the hero, and rotates the hero 45 degrees so the sword rotates with it. It compiled on the first try into a 949 byte swf.

What broke was running it. ADL closed instantly with exit code 3, no window and no trace output. Exit code 3 means ADL cannot find the runtime, so I looked inside the SDK, and the win and win64 runtime folders only had a placeholder file called sentinel. Then the AIR SDK Manager showed me a second copy of the SDK in OneDrive, broken the other way around: it had the Windows runtime but no adl or mxmlc in its bin folder. Neither copy could do both jobs.

I moved the broken copy out of the SDK folder so the manager stopped detecting it, reinstalled 51.5.1 from the manager, and pointed VS Code at the fresh install. It printed Hello AIR and confirmed the sword's parent is the hero. Then I deleted the leftover copies.

I also had the SDK path in my VS Code settings written with backslashes, which is invalid in JSON. Forward slashes fixed it.

Tomorrow is Lesson 2, the game loop and keyboard input.
