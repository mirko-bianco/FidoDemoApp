@echo OFF
copy ..\tests\Tests.dproj ..\tests\Tests.dproj.backup
type ..\tests\Tests.dproj | findstr /v TESTINSIGHT; > ..\tests\Tests.dproj.new
del ..\tests\Tests.dproj
copy ..\tests\Tests.dproj.new ..\tests\Tests.dproj
del allunitstotest.txt
del allsourcedirs.txt
rmdir /Q /S TestResults
rmdir /Q /S ../built/CodeCoverageResults

call CodeCoverage-CreateUnitsToTest.cmd ..\source\shared >> allunitstotest.txt
call CodeCoverage-CreateUnitsToTest.cmd ..\source\services >> allunitstotest.txt
call CodeCoverage-CreateUnitsToTest.cmd ..\source\client >> allunitstotest.txt
call CodeCoverage-CreateUnitsToTest.cmd ..\source\kvsetter >> allunitstotest.txt
call CodeCoverage-MakeSourceDirs.cmd ..\source\shared >> allsourcedirs.txt
call CodeCoverage-MakeSourceDirs.cmd ..\source\services >> allsourcedirs.txt
call CodeCoverage-MakeSourceDirs.cmd ..\source\client >> allsourcedirs.txt
call CodeCoverage-MakeSourceDirs.cmd ..\source\kvsetter >> allsourcedirs.txt

set Params=-e ..\built\Win32\Debug\Tests\Tests.exe -m ..\built\Win32\Debug\Tests\Tests.map -ife -spf allsourcedirs.txt -uf allunitstotest.txt -od ..\built\CodeCoverageResults\ -html -xml -xmllines -lt
call CodeCoverage.exe %Params%

del allunitstotest.txt
del allsourcedirs.txt
copy ..\tests\Tests.dproj.backup ..\tests\Tests.dproj
del ..\tests\Tests.dproj.backup
del ..\tests\Tests.dproj.new