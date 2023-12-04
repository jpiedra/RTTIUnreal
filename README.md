# RTTIUnreal: Real-Time TCP Integration for Unreal
Register and perform in-game events using TCP input

## To-do
- Make debug log messages configurable (`bDebug`)
- Make frequency of the command-running Timer configurable via an int var (`TimerDelay`)

## Requirements
Built against 227J, your mileage may vary with any other Unreal versions. Due to differences between Unreal and UT99 UnrealScript, this mod does *not* work with UT99.

For testing purposes, you might want a suitable command-line tool that can send basic network requests over TCP. I recommend [*ncat*](https://nmap.org/ncat/), which is a faithful update to *netcat* and works much like its predecessor, with some new features thrown in.

## Setup for Developers
Scripts are provided as a convenince for developers who wish to extend the capabilities of this mod. Not only is extending RTTIUnreal possible, it is encouraged!

First export the path to your Unreal installation:
`$env:UnrealPath=PATH_TO_YOUR_UNREAL_INSTALLATION`

Ensure that your Unreal config file (*System\Unreal.ini*) has an entry for the *RTTIUnreal* package added in the *[Editor.EditorEngine]* section along with all other *EditPackages* entries:
```
EditPackages=RTTIUnreal
```

To (re)build the .u package run in Powershell:
`.\util\build.ps1`

To quickly launch game server locally for testing:
`.\util\server.ps1`

To send data to the RTTIServer instance:
`echo "EVENT_OWNER?EVENT_NAME?EVENT_ARGS"|ncat server_ip server_port`

Example:
`echo "jaypeezy?spawn_monster?unreali.skaarjwarrior"|ncat 127.0.0.1 5900`

## TCP Interface
The following table provides information on the commands you or your middleware can send to the RTTIServer instance. This is done by sending the command in the following string format to the Unreal game server running an RTTIServer instance. Each of these commands corresponds to a hook which is implemented in the mod's source code:

|Action|Description|Syntax|Example|Notes|
|---|---------|---------|-----------|---------------|
|spawn_monster|Spawn an AI monster in-game (ScriptedPawn)|`username?spawn_monster?monster_class`|jaypeezy?spawn_monster?unreali.warlord||
|spawn_item|Randomly select a player and give them an item in-game (Inventory)|`username?spawn_item?inventory_class`|jaypeezy?spawn_item?unreali.superhealth|Works with all types of Inventory (armor, health, weapons, etc)|

*Note:* The `username` portion is simply to indicate who, or what, sent the command to RTTIServer. It can be, as some examples, the name of your middleware application, or whoever sent the command to the server. It does not necessarily correspond to the name of a player in your server.

## Configuration
This is a pretty bare-bones mod, so there are only a few configurable variables available in this release, found in *RTTIConfig.ini*:

|Variable|Description|Default Value|
|---|---|---|
|ListenPort|The RTTIServer actor will bind to this port upon creation, and listen for incoming command requests on it|5900|
|MaxClients|Defines the maximum number of clients that can connect to the RTTIServer during runtime|2|
|MaxAttempts|Defines the maximum number of times that RTTIUnreal will try to perform an action initiated from a command|5|


## Suggestions for Mod Extension
This is one of several possible routes you can take for refactoring this codebase if you want to extend the mod to add new hooks or features. The main objective here is to make minor changes to the source code, so that you end up with a *newly named* package that won't collide with the vanilla, unmodified *RTTIServer.u*.

### Changes to source code
1. Replace occurences to the package name *RTTIUnreal* with something else. Throughout this section we'll use *RTTIUnrealPlus* as the hypothetical name of our new package. You should use something more unique than that, to minimize the odds of package collision.
2. Rename this project's folder *RTTIUnreal* to the new name *RTTIUnrealPlus*
3. Rename the config file defined in *RTTIUnreal.uc* and *RTTIServer.uc* (in the parentheses) to the new name: 
    - `class RTTIUnreal expands Mutator config(RTTIUnrealPlus);`
    - `class RTTIServer extends TcpLink config(RTTIUnrealPlus);`
4. Then proceed to update all references to RTTIUnreal actors in the *.uc* files, which are qualified by package name. Anywhere you see the value `RTTIUnreal.` in reference to the package name, update them to be `RTTIUnrealPlus.` instead, the new package name.
5. If you're using the utility scripts provided herein, the `Util/server.ps1` script will need to be updated to use your new package in the server launch string: `& $cmd server map=Maps\DmStomp.unr?game=UnrealShare.DeathMatchGame?mutator=RTTIUnrealPlus.RTTIUnreal ini=Unreal.ini`
6. Lastly, update (or add) the *EditPackages* entry in *Unreal.ini* to refer to your new package: `EditPackages=RTTIUnrealPlus`

This process has not been tested, but should be sufficient to allow you to start developing your own, extended version of this mod. See below for details on adding your own hooks.

# Adding New Hooks
Some intermediate amount of UnrealScript knowledge is recommended.

I've tried to make the implementation of hooks as transparent as possible, so that adding new functionality is relatively easy. Review the source code of *RTTIUnreal.uc*, where the logic for commands/hooks is defined. This file is where you'll be making the required changes.

As a consequence of this objective, the intended syntax for possible commands is somewhat rigid. You're free to modify this code as you wish, but the easiest way to get going is if you follow the convention of `COMMAND_ISSUER?COMMAND_NAME?COMMAND_ARGUMENT` for command definition.

Start with deciding what your command is going to be called, and what you want it to do. Maybe you want to add a command to play a sound. Referring to the example above, the recommended convention for that command syntax, when used, would be: `username?play_sound?sound_name`. That middle portion, `play_sound`, is most important for now. 

With your command's name of `play_sound` decided on, the first step to implementing the command is to update `RunAct()` so that it can recognize this command. This is done by updating the switch statement therein to include a case named after the command:

```
//...
case "play_sound":
    isActSuccessful = (PlaySound(actOwner, actArgs));
    break;
//...
```

When you/your middleware sends the command in the format discussed above, `RunAct()` will now match the command name `play_sound` with the corresponding hook `PlaySound()`, which is not yet defined.

Now proceed to define the `PlaySound()` hook. You might want to define a hook that retries a certain number of times (use the `MaxAttempts` variable for iteration control!), such as what `SpawnMonster()` implements. Or, you might want it to try only once and then back off upon failure, like `SpawnItem()`. Whatever you decide, adhere to the function signature used throughout, which is to return a `bool` value. This is required so that the logic in `RunAct()` can determine whether the action completed successfully or not, via the `isActSuccessful` value which receives the returned boolean value of your hook:

```
function bool PlaySound(string actOwner, string actArgs) {
    // logic goes here 
    ...
    // return true or false depending on whether this hook function ran as intended
}
```

These steps are the bare minimum required to implement a command and matching hook function, adhering to the recommended constraints. GLHF!

