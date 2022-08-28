First export path to your Unreal installation:
`$env:UnrealPath=PATH_TO_YOUR_UNREAL_INSTALLATION`

To (re)build the .u package run in Powershell:
`.\util\build.ps1`

To quickly launch game server locally for testing:
`.\util\server.ps1`

To send data to the RTTIServer instance:
`echo "EVENT_OWNER?EVENT_NAME?EVENT_ARGS"|netcat server_ip server_port`
`echo "jaypeezy?spawn_monster?unreali.skaarjwarrior"|netcat 127.0.0.1 5900`
