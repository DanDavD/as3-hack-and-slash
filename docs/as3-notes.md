## How AS3 code becomes a running game

I write my code in .as files, but nothing runs those files directly. The compiler, mxmlc, reads them and produces a .swf file. mxmlc is itself a Java program, which is the only reason the project needs a JDK. That is the only moment Java is involved. Once the .swf exists, the JVM is out of the picture.

It is actually closer to C# than to Java. In C# the compiler turns .cs files into a .dll or .exe full of IL, and the CLR runs that. In AS3, mxmlc turns .as files into a .swf full of ABC bytecode, and AVM2 runs that. The compiler being written in Java has nothing to do with how the game runs.

The mistake that taught me this: I thought mxmlc used the JVM to run my code, and that a separate swf compiler then ran the game. Both parts were wrong. The JVM only runs the compiler, and the .swf is already the finished compiled product. It needs a runtime, not another compiler.

## SWF files and ABC bytecode

A .swf is what comes out of compilation. Inside it is ABC, which stands for ActionScript Byte Code, along with the assets the game uses, like images, sounds and fonts. I think of it like a Java .jar or a .NET assembly, a package of bytecode and resources that the CPU cannot run directly.

In my project the compiled file lands in the bin folder as HackAndSlash.swf, because that is where the output option in asconfig.json points.

## AVM2 and the runtimes

The virtual machine that executes ABC bytecode is AVM2, the ActionScript Virtual Machine 2. It either interprets the bytecode or JIT compiles it to native code, the same idea as the JVM or the CLR. AVM2 does not exist on its own. It always comes inside a runtime.

I know of three runtimes. Flash Player was the browser plugin, and it has been dead since 2020. Adobe AIR, now maintained by Harman, runs swf content as desktop apps, and it is the one I am using. Ruffle is a modern Flash emulator written in Rust. Dungeon Rampage started as a browser Flash game, so once Flash died, packaging with AIR is one of the ways a game like that can keep living on desktop.

## AIR SDK, ADL and packaging

The Harman AIR SDK is the toolkit. It includes mxmlc, the AIR runtime and the tools to debug and package apps. I am on version 51.5.1. The app descriptor, Main-app.xml, defines the window and app settings, and its namespace version has to match the SDK version, which for me is 51.5.

In VS Code, Ctrl+Shift+B runs mxmlc and builds the swf. F5 launches ADL, the AIR Debug Launcher, which loads the swf in the AIR runtime and connects the debugger so I can see trace output. To ship the game, the Package Adobe AIR Application command builds a Windows captive runtime bundle into the dist folder. Captive runtime means the AIR runtime travels inside the app together with my swf, so whoever plays it does not need to install AIR. It reminds me of a self contained .NET publish.

ADL does not print an error message when it fails, it just exits with a number. Exit code 3 means it cannot find the runtime. That is exactly what happened to me on day one. My SDK compiled fine, but the runtimes folder only had Mac and Android runtimes, and the win and win64 folders held nothing but a placeholder file called sentinel. Compiling and running depend on different parts of the SDK, so a working compiler does not prove the SDK can run anything. The fix was a clean reinstall from the AIR SDK Manager instead of patching copies together. The manager detects any SDK folder inside its location folder, so a broken copy has to be moved out before it will offer to install that version again.

## VS Code settings and JSON paths

The ActionScript and MXML extension finds the SDK through the as3mxml.sdk.framework setting in the settings.json file inside the .vscode folder. I had written the path with normal Windows backslashes. In JSON a backslash starts an escape sequence, so a backslash followed by a letter like U is invalid, and the extension could fail to find the SDK.

The fix was switching to forward slashes, which Windows accepts just fine. It is the same trap as Windows paths in a normal C# string or a Python string, where the backslash is also an escape character. In Python I would use a raw string, but JSON has no raw strings, so forward slashes it is.

## Packages and files

A package in AS3 works like a namespace in C# or a package in Java. The rule is strict: the folder has to match the package name. My Main.as sits at the root of the src folder, so its package has no name. If I make a Player class inside a game folder, its file has to start with package game.

Like Java, every file holds one public class, and the file name has to match the class name exactly.

On day 3 I made my first one, a game folder with Hero, Entity and Input inside. To use them from Main I import game.Hero, like a using in C#, except AS3 imports one class at a time unless I write game with a star.

## The main class and the SWF metadata tag

My Main class extends Sprite, and it has to extend Sprite or MovieClip because the runtime adds it to the screen when the game starts. Its constructor is the entry point of the whole game, my equivalent of main in C++ or Java.

Right above the class there is a SWF metadata tag in square brackets, the same syntax as a C# attribute. It tells the compiler the stage size, the frame rate and the background color. Mine sets 960 by 540, 60 frames per second and a dark background.

## trace

trace is the AS3 version of Console.WriteLine in C#, print in Python or System.out.println in Java. My first line of AS3 was a trace call printing Hello AIR in the Main constructor. The catch is that trace output only shows up when I run with the debugger through F5.

## The display list

Everything on screen lives in a tree called the display list. The stage is the root, my Main sprite is its child, and everything else in the game hangs off that. An object only gets drawn if it is connected to the tree with addChild. Creating a Sprite is not enough.

Children are positioned relative to their parent. If the player has a sword as a child and the player moves or rotates, the sword moves and rotates with it. So the tree is both what gets drawn and how things are attached to each other.

To draw shapes without any image files, every Sprite has a graphics property. I call beginFill with a hex color, then drawRect with x, y, width and height, then endFill. For the hero I drew the square starting at negative 20 on both axes, so the square is centered on the sprite's own origin and rotates around its center instead of its top left corner. The sword is a child with x set to 24, which is measured from the hero's center, not from the screen.

## Basic types and type annotations

In AS3 the type goes after the name, separated by a colon, for variables, parameters and return types. Python type hints use the same order, so it felt familiar. C#, C++ and Java put the type first. Functions that return nothing declare void as their return type at the end, after the parameters.

int is a 32 bit signed integer and Number is a 64 bit double. There is no float type at all, which is different from C#, C++ and Java. String and Boolean are what they sound like, and const works like in C#.

Array is dynamic and untyped, like a Python list. Vector is the typed version, like List in C# or std::vector in C++, and it is faster. The syntax is a bit odd, since there is a dot between Vector and the angle brackets with the element type.

## Events and listeners

Pretty much everything in AS3 runs on events. I call addEventListener with an event type and a function, and that function gets called when the event happens. Same idea as += on a C# event. The types are constants like Event.ENTER_FRAME, so if I make a typo the compiler yells at me instead of the listener just never firing.

removeEventListener is the minus equals. It needs the exact same type and function I added, and calling it when the listener is not there does nothing, so it is safe. Adding the same function twice does not add it twice either. A listener I forget to remove keeps running forever, so for things that only matter for a moment, like a sword swing, I add an ENTER_FRAME listener when it starts and remove it when it ends.

## The stage is null in the constructor

A display object only gets its stage once it is on the display list, and Main is not on it yet when its constructor runs. So touching stage in there crashes. The fix is to check if stage exists, and if not, wait for ADDED_TO_STAGE and do the setup in an init function. Kind of like Awake versus Start in Unity.

## The game loop

No update method to override here. The game loop is just a listener for ENTER_FRAME, which fires every frame, so 60 times a second for me. Right now the hero moves 4 pixels per frame, which means if the game lags, the hero slows down too. Delta time can wait.

## Keyboard input

Key events only tell me when a key goes down or up, not if it is being held. So I keep an object of key codes set to true or false and check it every frame. The listeners go on the stage because it gets every key event, no matter what has focus. I also clear everything when the window loses focus, otherwise a key released while alt tabbed stays stuck forever.

KEY_DOWN is not fired once per press. While a key is held the operating system repeats it, so KEY_DOWN keeps coming. For a tap, like the attack key, I only count it if the key was not already down in my map.

## Diagonals, clamping and rotation

Holding two keys gives a move of 1 on both axes, which has a length of about 1.41, so diagonals would be faster. Dividing by the length fixes it. Also y goes down in Flash, so up is negative.

To keep the hero on screen I clamp x and y with Math.max and Math.min. To make it face where it walks I use Math.atan2, but that gives radians and rotation wants degrees, so I convert it. Math is radians, display objects are degrees, easy to mix up.

## Classes, extends and super

Pretty much C# or Java. A class extends one parent and super calls the parent constructor, like base in C#. If I do not call super myself the compiler adds it. Entity extends Sprite and Hero extends Entity, so a Hero is still a Sprite and can go on the display list.

One difference from C++: if the parent constructor calls a function the child overrides, the child version runs. Entity calls draw in its constructor and Hero's draw is the one that runs. In C++ that would call the base version.

## override and access modifiers

override is required when replacing a parent function, without it the compiler errors. There is no abstract, so Entity has an empty draw for subclasses to fill in.

public, private and protected work like C#. internal means visible inside the same package, like package private in Java. The catch is that internal is the default when I write nothing, while in C# members default to private.

## Getters and setters

get and set functions are C# properties. From outside hero.speed looks like a normal variable but it runs my function, so the setter can block negative values. The getter cannot share a name with a variable, so the real value lives in a variable called speed with an underscore in front, which is the usual AS3 naming.

## static

Same as C#. A static member belongs to the class, not to each object, so Hero.SIZE works without any hero existing. static const is how I make class constants.

## EventDispatcher and dispatchEvent

Anything that extends EventDispatcher can fire events with dispatchEvent. Sprite already extends it, which is why every display object has addEventListener. A class that is never on screen, like my Combo, can just extend EventDispatcher directly instead of Sprite. It is the AS3 version of a class with a C# event on it, except the event is a string type and anyone can listen to any type.

## Custom events and clone

To send extra data with an event I extend Event, add my own fields and type constants, and pass the type to super. In C# the data would go in an EventArgs, here the event object itself carries it.

The gotcha is clone. If an event that was already dispatched gets dispatched again, like my Hero passing the combo events up to Main, Flash dispatches a copy made with clone. If I do not override clone, the copy is a plain Event without my hit number, and a listener that expects a ComboEvent gets a type error. So every custom event overrides clone and returns a new one with the same values.

## getTimer

getTimer, from flash.utils, returns the milliseconds since the app started as an int. It is a free function, not a method on a class, so I import flash.utils.getTimer by itself. To time something I save getTimer when it starts and subtract later, like a Stopwatch in C# or time in Python. Unlike counting frames, it stays correct even if the game lags.

## switch

switch works like C and C++. Cases fall through to the next one unless there is a break, and I can stack two cases on top of each other to share code. C# only allows that when the first case is empty, and AS3 also allows switching on strings, which is how my combo states work.

## Local and global coordinates

Every display object has its own coordinate space, where its origin is its x and y and its axes turn with its rotation and stretch with its scale. A child's x and y are in its parent's space, not the screen's. So the sword's blade going from 24 to 54 along x means nothing on screen until I take the hero's position and rotation and the sword's rotation and scale into account.

localToGlobal does that for me. I give it a Point in the object's own space and it returns where that point is on the stage. globalToLocal goes the other way, from the stage into some object's space. It is like transform.TransformPoint and InverseTransformPoint in Unity. To compare a blade point with an enemy box I go from sword space to global with localToGlobal, then from global to the enemy's parent space with globalToLocal, because that is the space the enemy's x and y live in.

## Point and Rectangle

Both live in flash.geom. Point is just an x and a y, like Vector2 without most of the math. Rectangle has x, y, width and height, and it comes with containsPoint to check if a point is inside it and intersects to check if two rectangles overlap at all. Two overlapping boxes is the classic AABB check I would write by hand in C++, here it is one call.

## hitTestObject and getBounds

hitTestObject checks if the bounding boxes of two display objects overlap, and getBounds returns that box as a Rectangle in whatever coordinate space I pass to it. The catch is that both include all the children. My hero's bounds include the sword, so using them for the enemy touching the hero would count a touch on the blade as a touch on the hero. They are also axis aligned, so a rotated square gets a bigger box than it looks. That is why my Entity builds its own body box from x, y and its half size.

## Base class vs interface

A base class is for sharing code. My Enemy has the HP bar, the knockback and the update steps, and Chaser, Charger and Shooter only fill in what is different. An interface is only a contract, a list of functions with no code at all, for when unrelated classes need to answer the same questions. My Projectile is a Sprite and not an Entity, it has no HP, but it hurts the hero just like an enemy, so both implement IHarmful and Main checks them with the same function.

Same rules as C# and Java: a class extends one parent but can implement any number of interfaces, and it can do both at once, like Enemy extends Entity implements IHarmful. The interface name starting with an I is just a convention, also from C#.

## Writing an interface

It is written with the interface keyword instead of class, and its functions have no body and no access modifier, because everything in an interface is public anyway. Writing public in there is actually a compile error. Getters work too, so a function get hitBox in the interface means any class with a public hitBox getter fulfills it, even if it got it from its parent like Enemy gets it from Entity.

## final

final on a function means subclasses cannot override it, like sealed on a method in C#, and final on a class means nothing can extend it. My Enemy update is final, so every enemy always runs the knockback and the clamp, and a subclass can only change the think part. It is the template method pattern, the base class decides the steps and the subclass fills one in.

## Overriding getters and why statics are not virtual

A static const belongs to one class. If Enemy reads COLOR it gets Enemy.COLOR, there is no way for it to see Charger.COLOR, because statics are not looked up through the object like normal functions. So for something each subclass changes, like the body color, I use a protected getter and override it, override protected function get bodyColor. Getters are functions, so they follow the same override rules as any other function.

## More on Vector

push adds at the end, removeAt removes one index and shifts everything after it, and setting length to 0 empties it, like Add, RemoveAt and Clear on a C# List. A Vector of Enemy accepts a Chaser or a Charger because they are both Enemy, the same as a List of a base class in C#.

When removing while looping, go backwards. Going forward, removing index 3 moves the next element into 3, the loop goes on to 4, and that element never gets checked. Same trap as removing from a list while iterating in any language, except here there is no exception, it just silently skips.

## removeChild is not delete

AS3 has no delete for objects, the garbage collector frees an object once nothing references it anymore. removeChild only takes it off the screen. If anything still points at it, a Vector, a variable, a listener, it stays in memory, and any ENTER_FRAME listener on it keeps running even though nobody can see it.

So killing something properly is a list. Take it off the display list, remove its listeners, and drop it from every Vector or variable that holds it. My enemies have a destroy function for their part, and Main does the rest.

## Listeners and who holds whom

addEventListener stores a reference to the listener inside the dispatcher. So when Main listens to an enemy, the enemy points at Main, not the other way, and that alone does not keep the enemy alive. The dangerous direction is the opposite one, an enemy listening to the stage or the hero, because then the long lived object points at the enemy and it can never be freed. For that case addEventListener has a useWeakReference parameter, the fifth one, but I would rather remove the listener myself than depend on it.

ENTER_FRAME is special because it fires on every display object, on the screen or not. In my test, a Charger removed in the middle of its blinking with its own ENTER_FRAME listener still on survived 30 forced garbage collections and kept blinking invisibly. A plain Sprite with the same kind of listener was freed right away, so the behavior is not something to rely on either way. Remove what you add.

## Weak Dictionary and System.gc

Dictionary is the AS3 version of a C# Dictionary with objects as keys. Passing true to its constructor makes the keys weak, so being a key does not count as a reference, and when the object is collected the key just disappears from it. That makes a cheap leak detector: put every dead enemy in a weak Dictionary, force a collection, and anything still in there is being held by something.

System.gc forces a full collection, but only in AIR and the debug Flash Player. It did not free things killed in the same frame, probably because the object is still on that frame's stack, so I call it a few hundred milliseconds after the wave ends and count when the next wave spawns.
