CD %PROGRAMFILES(X86)%\Steam\steamapps\common\GarrysMod || EXIT
set /p "confirm=UPDATE NPCDAEMON? (y/n) "
if not %confirm%=="y" exit
bin\gmpublish.exe update -id 2574407396 -addon npcdaemon.gma