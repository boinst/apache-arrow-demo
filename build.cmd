@echo off

REM ###
REM ### Build Native project
REM ###


if [%1] == [] goto :USAGE

REM ### Update "ztools", which includes the tool "nant"
powershell.exe -noprofile -ExecutionPolicy Bypass -noninteractive -nologo -file "%~dp0.\build\tools\zulfiqar2.ps1"

REM ### Execute build process
"%~dp0.\build\tools\ztools\nant-0.92\nant-0.92\bin\NAnt.exe" -buildfile:"%~dp0.\build\nant\Build.nant" -logfile:"%~dp0.\build\logs\nant-release-x64.log" -D:platform=x64 -D:buildConfiguration=Release %* || goto :ERROR
"%~dp0.\build\tools\ztools\nant-0.92\nant-0.92\bin\NAnt.exe" -buildfile:"%~dp0.\build\nant\Build.nant" -logfile:"%~dp0.\build\logs\nant-debug-x64.log" -D:platform=x64 -D:buildConfiguration=Debug %* || goto :ERROR

echo Build completed successfully
goto :END

:USAGE
echo Syntax error in command-line arguments.
echo Try executing: 
echo     build.cmd Build Test
goto :END

:ERROR
echo Build FAILED with exit code %ERRORLEVEL%
exit /b %ERRORLEVEL%

:END
exit /b 0
