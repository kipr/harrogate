@echo off

set path=%1
:loop
shift
if [%1]==[] goto afterloop
set GCC_ARGUMENTS=%GCC_ARGUMENTS% %1
goto loop
:afterloop

cd  %path%

gcc.exe %GCC_ARGUMENTS%