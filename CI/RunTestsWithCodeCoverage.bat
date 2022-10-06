@ECHO OFF
DEL allunitstotest.txt
DEL allsourcedirs.txt
RMDIR /Q /S TestResults
RMDIR /Q /S ../built/CodeCoverageResults

call CodeCoverage-CreateUnitsToTest.bat ..\source\shared >> allunitstotest.txt
call CodeCoverage-CreateUnitsToTest.bat ..\source\services >> allunitstotest.txt
call CodeCoverage-CreateUnitsToTest.bat ..\source\client >> allunitstotest.txt
call CodeCoverage-CreateUnitsToTest.bat ..\source\kvsetter >> allunitstotest.txt
call CodeCoverage-MakeSourceDirs.bat ..\source\shared >> allsourcedirs.txt
call CodeCoverage-MakeSourceDirs.bat ..\source\services >> allsourcedirs.txt
call CodeCoverage-MakeSourceDirs.bat ..\source\client >> allsourcedirs.txt
call CodeCoverage-MakeSourceDirs.bat ..\source\kvsetter >> allsourcedirs.txt

SET Params=-e ../built/Win32/Debug/Tests/Tests.exe -m ../built/Win32/Debug/Tests/Tests.map -ife -spf allsourcedirs.txt -uf allunitstotest.txt -od ..\built\CodeCoverageResults\ -html -xml -xmllines -lt
CodeCoverage.exe %Params%

DEL allunitstotest.txt
DEL allsourcedirs.txt
