@ECHO OFF 
call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat" 
SET config="Release" 
SET platform="Linux64" 
msbuild /m C:\Development\Sources\FidoApp\source\shared\FidoAppShared.dproj /t:build /p:Config=%config% /p:platform=%platform% /v:diag /fl 
if NOT %ERRORLEVEL%==0 EXIT %ERRORLEVEL%
msbuild /m C:\Development\Sources\FidoApp\source\kvsetter\KVSetter.dproj /t:build /p:Config=%config% /p:platform=%platform% /v:diag /fl 
if NOT %ERRORLEVEL%==0 EXIT %ERRORLEVEL%
msbuild /m C:\Development\Sources\FidoApp\source\services\authentication\AuthenticationService.dproj /t:build /p:Config=%config% /p:platform=%platform% /v:diag /fl 
if NOT %ERRORLEVEL%==0 EXIT %ERRORLEVEL%
msbuild /m C:\Development\Sources\FidoApp\source\services\authorization\AuthorizationService.dproj /t:build /p:Config=%config% /p:platform=%platform% /v:diag /fl 
if NOT %ERRORLEVEL%==0 EXIT %ERRORLEVEL%
msbuild /m C:\Development\Sources\FidoApp\source\services\users\UsersService.dproj /t:build /p:Config=%config% /p:platform=%platform% /v:diag /fl 
if NOT %ERRORLEVEL%==0 EXIT %ERRORLEVEL%
