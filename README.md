# Real-Time TCP Integration for Unreal
Register and perform in-game events using TCP input

## Requirements
Built against 227J, your mileage may vary with anything else

Most likely *won't* work with UT99

## Setup
First export path to your Unreal installation:
`$env:UnrealPath=PATH_TO_YOUR_UNREAL_INSTALLATION`

To (re)build the .u package run in Powershell:
`.\util\build.ps1`

To quickly launch game server locally for testing:
`.\util\server.ps1`

To send data to the RTTIServer instance:
`echo "EVENT_OWNER?EVENT_NAME?EVENT_ARGS"|netcat server_ip server_port`

Example:
`echo "jaypeezy?spawn_monster?unreali.skaarjwarrior"|netcat 127.0.0.1 5900`

Action command usage:

|Action|Description|Syntax|Example|Notes|
|---|---------|---------|-----------|---------------|
|spawn_monster|Spawn an AI monster in-game (ScriptedPawn)|`username?spawn_monster?monster_class`|jaypeezy?spawn_monster?unreali.warlord||
|spawn_item|Randomly select a player and give them an item in-game (Inventory)|`username?spawn_item?inventory_class`|jaypeezy?spawn_item?unreali.superhealth|Works with all types of Inventory (armor, health, weapons, etc)|