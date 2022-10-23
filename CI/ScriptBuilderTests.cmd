echo @ECHO OFF > .\ci\BuildTests.cmd
echo call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat" >> .\ci\BuildTests.cmd
echo SET DUNITX=$(BDS)\source\dunitx >> .\ci\BuildTests.cmd
echo SET config="Debug" >> .\ci\BuildTests.cmd
echo SET platform="Win32" >> .\ci\BuildTests.cmd
for /f tokens^=* %%i in ('where /r .\tests *.dproj')do (echo/msbuild /m %%~dpi%%~nxi /t:build /p:Config=%%config%% /p:platform=%%platform%% /v:diag /fl &echo if NOT %%ERRORLEVEL%%==0 EXIT %%ERRORLEVEL%%) >> .\ci\BuildTests.cmd