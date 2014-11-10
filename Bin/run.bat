@ECHO OFF

REM Run the environment setup script.
IF EXIST env.bat (CALL env.bat)

REM The framework's root directory.
SET OLD_CD=%CD%
SET FRAMEWORK_ROOT=%~dp0\..

REM Launcher script for the framework
REM Command line arguments are accumulated and passed to ruby main.rb
CD %FRAMEWORK_ROOT%
ruby main.rb %*
CD %OLD_CD%
