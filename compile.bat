echo OFF
cls
 
echo.

echo _____________________________________________________________________
echo.
echo                        Compiling %1...
echo _____________________________________________________________________

echo.
echo.

ml  /coff  /c  /Zi  /Fl  %1.asm

echo.
IF NOT EXIST %1.obj echo -------------- ERRRORS ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
echo.

link /subsystem:console /out:%1.exe %1.obj ..\..\Irvine\User32.Lib \masm32\lib\kernel32.lib ..\..\Irvine\Irvine32.lib ../macros/convutil201604.obj ../macros/io.obj ../macros/kernel32.lib ../macros/utility201609.obj 

IF NOT EXIST %1.exe echo.
IF EXIST %1.exe echo _____________________________________________________________________

dir
echo _____________________________________________________________________
echo.

IF NOT EXIST %1.exe echo      ---- Errors have occurred and compilation has failed ---- 
IF EXIST %1.exe echo                 ---- Compilation complete ----

echo _____________________________________________________________________
echo.

IF NOT EXIST %1.exe goto end
echo.
echo.

CHOICE /M "    Execute %1?"
IF errorlevel 2 goto end

%1
:end:
echo ON