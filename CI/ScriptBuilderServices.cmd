echo @ECHO OFF > .\ci\BuildServices.cmd
echo call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat" >> .\ci\BuildServices.cmd
echo SET config="Release" >> .\ci\BuildServices.cmd
echo SET platform="Linux64" >> .\ci\BuildServices.cmd
for /f tokens^=* %%i in ('where /r .\source\shared *.dproj')do (echo/msbuild /m %%~dpi%%~nxi /t:build /p:Config=%%config%% /p:platform=%%platform%% /v:diag /fl &echo if NOT %%ERRORLEVEL%%==0 EXIT %%ERRORLEVEL%%) >> .\ci\BuildServices.cmd
for /f tokens^=* %%i in ('where /r .\source\kvsetter *.dproj')do (echo/msbuild /m %%~dpi%%~nxi /t:build /p:Config=%%config%% /p:platform=%%platform%% /v:diag /fl &echo if NOT %%ERRORLEVEL%%==0 EXIT %%ERRORLEVEL%%) >> .\ci\BuildServices.cmd
for /f tokens^=* %%i in ('where /r .\source\services *.dproj')do (echo/msbuild /m %%~dpi%%~nxi /t:build /p:Config=%%config%% /p:platform=%%platform%% /v:diag /fl &echo if NOT %%ERRORLEVEL%%==0 EXIT %%ERRORLEVEL%%) >> .\ci\BuildServices.cmd