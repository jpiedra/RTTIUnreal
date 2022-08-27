Write-Host "Make sure to export env var UnrealPath to your installation:"
Write-Host "`$env:UnrealPath = 'C:\Unreal227J'"

Remove-Item -Path "$($env:UnrealPath)\System\RTTIUnreal.u" -Confirm:$False

$cmd = "$($env:UnrealPath)\System\ucc.exe"

& $cmd make