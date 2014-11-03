@ECHO OFF

REM Run the environment setup script.
IF EXIST env.bat (CALL env.bat)

REM Launcher script for the framework
REM Command line arguments are accumulated and passed to ruby main.rb
ruby main.rb %*
