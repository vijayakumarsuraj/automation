@ECHO OFF

REM Append '-execute' to the first argument and remove it.
SET APPLICATION_NAME=%1-execute
SHIFT

REM Combine the rest of the arguments.
SET ARGS=
:ParseLoop
IF "%1"=="" GOTO ParseLoopEnd
IF "%ARGS%"=="" (SET ARGS=%1) ELSE (SET ARGS=%ARGS% %1)
SHIFT
GOTO ParseLoop
:ParseLoopEnd

REM Call 'run.bat'.
CALL run.bat %APPLICATION_NAME% %ARGS%
