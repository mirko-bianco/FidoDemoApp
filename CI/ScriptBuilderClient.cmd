echo @ECHO OFF > .\ci\BuildClient.cmd
echo call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat" >> .\ci\BuildClient.cmd
echo SET config="Release" >> .\ci\BuildClient.cmd
echo SET platform="Win32" >> .\ci\BuildClient.cmd
for /f tokens^=* %%i in ('where /r .\source\shared *.dproj')do (echo/msbuild /m %%~dpi%%~nxi /t:build /p:Config=%%config%% /p:platform=%%platform%% /v:diag /fl &echo if NOT %%ERRORLEVEL%%==0 EXIT %%ERRORLEVEL%%) >> .\ci\BuildClient.cmd
for /f tokens^=* %%i in ('where /r .\source\client *.dproj')do (echo/msbuild /m %%~dpi%%~nxi /t:build /p:Config=%%config%% /p:platform=%%platform%% /v:diag /fl &echo if NOT %%ERRORLEVEL%%==0 EXIT %%ERRORLEVEL%%) >> .\ci\BuildClient.cmd