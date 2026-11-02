## About

This is a small dungeon crawler hack and slash that I am building in pure ActionScript 3 on Adobe AIR with the Harman SDK, as a desktop app. I am using it to learn AS3 from zero.

I am tracking the whole 30 day plan on a public Trello board, one card per day, so anyone can see what I am working on and what is next. https://trello.com/b/b7Z9nHBL/as3-hack-and-slash-30-days

## Scope

The plan is one hero with a three hit melee combo, rooms whose doors unlock once every enemy is dead, two or three enemy types plus a boss room, and health drops, an HP UI, game over and restart.

## Building

You need Java JDK 17 or 21, the Harman AIR SDK, and VS Code with the ActionScript and MXML extension and the Debugger for SWF extension. I installed the SDK with the AIR SDK Manager, and a clean install from there is the safest way to get every runtime the SDK needs.

In VS Code, run the ActionScript Select Workspace SDK command and pick the AIR SDK. Press Ctrl Shift B to compile and F5 to run. For a Windows captive runtime build, run the ActionScript Package Adobe AIR Application command, which puts the result in the dist folder.

## Docs

My daily devlog is devlog.md and my AS3 reference notes are as3-notes.md, both inside the docs folder.
