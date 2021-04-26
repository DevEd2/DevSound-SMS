@echo off
set name=devsound

wla-z80 -v -o main.o Main.asm
if errorlevel 1 goto :fail
wlalink -d -v -s main.lk %name%.sms
if errorlevel 1 goto :fail
goto :done

:fail
echo Build failed!
goto:eof

:done
rem cleanup
if exist *.o del *.o
if exist .wla* del .wla*
echo Build finished.