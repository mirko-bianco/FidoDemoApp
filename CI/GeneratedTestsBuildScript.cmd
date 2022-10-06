@ECHO OFF 
call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat" 
SET DUNITX=$(BDS)\source\dunitx 
SET config="Release" 
SET platform="Win32" 
msbuild /m C:\Development\Sources\FidoApp\tests\Tests.dproj /t:build /p:Config=%config% /p:platform=%platform% /v:diag /fl 
if NOT %ERRORLEVEL%==0 EXIT %ERRORLEVEL%
