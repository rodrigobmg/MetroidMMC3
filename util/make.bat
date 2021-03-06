REM Make.bat

:start
@echo off

REM Fail if no source directory has been passed.
if "%1" neq "" (goto has_src_dir)
echo Cannot run this script from the command line.
exit /b
:has_src_dir

REM Set the work directory.
set workdir=obj
set srcdir=%1

REM Delete existing work directory and create a new work directory
if not exist %workdir% goto make_work_dir
rmdir /s /q %workdir%
:make_work_dir
mkdir %workdir%

REM Copy data/code from the source directory to the work directory.
echo|set /p=Copying make files...
copy %srcdir%\make.txt %workdir%\make.txt >NUL
echo  done.
echo|set /p=Copying Data files... 
mkdir %workdir%\data
xcopy %srcdir%\data %workdir%\data /S /q
echo|set /p=Copying PRG files... 
mkdir %workdir%\PRG
xcopy %srcdir%\PRG %workdir%\PRG /S /q
REM util\if6502 %srcdir%/code %workdir%/code -all
echo|set /p=Copying Code files... 
mkdir %workdir%\code
xcopy %srcdir%\code %workdir%\code /S /q

REM Create make.asm file to combine all assembled PRGs into the final ROM.
if not exist %workdir%\make.asm goto make_make_asm
del %workdir%\make.asm
:make_make_asm
copy /y NUL %workdir%\make.asm >NUL
echo .outfile "bin/%srcdir%.nes" >> %workdir%\make.asm
echo .include "code/header.asm" >> %workdir%\make.asm

REM Compile each of the banks in make.txt, and add each to the make.asm file.
for /f "tokens=1-5 delims=," %%G in (%workdir%/make.txt) do (
    if %%G==map (
        echo Mapping %%H:
        util\ophis.exe -m "%workdir%/map.txt" "%workdir%/%%H"
        del "ophis.bin"
        util\getlabels.exe "%workdir%/map.txt" "%workdir%/%%I" "%%J" "%%K"
        REM del "%workdir%\map.txt"     -- NOT necessary, as it is in obj folder.
    )
    if %%G==prg (
        echo Assembling %%H:
        util\ophis.exe -o "%workdir%/%%I.bin" "%workdir%\PRG\%%I.asm"
        echo .incbin "%%I.bin" >> %workdir%\make.asm
    )
)

if not exist bin goto move
rmdir /s /q bin
:move
mkdir bin

REM Combine the banks
echo Combining banks into ROM:
util\ophis.exe obj/make.asm

choice /c:yn /m "Make again?"
if errorlevel 2 goto :end
if errorlevel 1 goto :start

:end
exit /b
