@echo off

for /f "tokens=1,* delims= " %%a in ("%*") do set GCC_ARGUMENTS=%%b

cd  %1

gcc.exe %GCC_ARGUMENTS%