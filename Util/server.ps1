Write-Host "Make sure to export env var UnrealPath to your installation:"
Write-Host "`$env:UnrealPath = 'C:\Unreal227J'"

$cmd = "$($env:UnrealPath)\System\ucc.exe"

& $cmd server map=Maps\DmAriza.unr?game=UnrealShare.DeathMatchGame?mutator=RTTIUnreal.RTTIUnreal