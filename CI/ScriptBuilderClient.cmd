echo @ECHO OFF > GeneratedClientBuildScript.cmd
echo call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat" >> GeneratedClientBuildScript.cmd
echo SET config="Release" >> GeneratedClientBuildScript.cmd
echo SET platform="Win32" >> GeneratedClientBuildScript.cmd
for /f tokens^=* %%i in ('where /r .\..\source\shared *.dproj')do (echo/msbuild /m %%~dpi%%~nxi /t:build /p:Config=%%config%% /p:platform=%%platform%% /v:diag /fl &echo if NOT %%ERRORLEVEL%%==0 EXIT %%ERRORLEVEL%%) >> GeneratedClientBuildScript.cmd
for /f tokens^=* %%i in ('where /r .\..\source\client *.dproj')do (echo/msbuild /m %%~dpi%%~nxi /t:build /p:Config=%%config%% /p:platform=%%platform%% /v:diag /fl &echo if NOT %%ERRORLEVEL%%==0 EXIT %%ERRORLEVEL%%) >> GeneratedClientBuildScript.cmd