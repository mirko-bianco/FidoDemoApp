echo @ECHO OFF > .\ci\BuildUtilities.cmd
echo call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat" >> .\ci\BuildUtilities.cmd
echo SET config="Release" >> .\ci\BuildUtilities.cmd
echo SET platform="Win32" >> .\ci\BuildUtilities.cmd
for /f tokens^=* %%i in ('where /r .\utilities *.dproj')do (echo/msbuild /m %%~dpi%%~nxi /t:build /p:Config=%%config%% /p:platform=%%platform%% /v:diag /fl &echo if NOT %%ERRORLEVEL%%==0 EXIT %%ERRORLEVEL%%) >> .\ci\BuildUtilities.cmd