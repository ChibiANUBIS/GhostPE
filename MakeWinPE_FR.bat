rem MUST RUN WITH THE DEPLOYMENT TOOLS FROM THE ADK IN ADMIN
@set "WinPE=GhostPE"
@echo off
echo The workingdirectory is %SystemDrive%\%WinPE%
echo The iso name is %Winpe%; location is workingdirectory %SystemDrive%\%WinPE%
for /f "tokens=3 delims=: " %%a in ('dism /online /english /get-intl ^| findstr /I "System locale"') do set "lang=%%a"
echo The Winpe language %lang% is the same of the System locale. Can be changed with set "lang=xx-XX" 
echo To include extra packages, uncomment the lines call :AddPackage package name
rem set "lang=en-US"    &rem language can be changed here
echo %WinPE% generated for %lang% language
call "%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"
set "target=%SystemDrive%\%WinPE%" & Rem Establish workingdirectory
rem chcp 1252 >nul 2>&1 & rem chcp 1252 causes E:|findstr /B /E /I "[A-Z]:" to hang !
::
rd /s /q "%target%" >nul 2>&1
rem Make sure the destination directory does not exist
if exist "%target%" (
  echo ERROR: "%target%" destination directory exists - abort. & pause & exit /b)
robocopy "%WinPERoot%\x86\media" "%target%\media"
robocopy "%WinPERoot%\x86\media\boot" "%target%\media\boot"
robocopy "%WinPERoot%\x86\media\boot\en-us" "%target%\media\boot\en-us"
robocopy "%WinPERoot%\x86\media\boot\%lang%" "%target%\media\boot\%lang%"
robocopy "%WinPERoot%\x86\media\boot\Fonts" "%target%\media\boot\fonts"
robocopy "%WinPERoot%\x86\media\boot\Resources" "%target%\media\boot\Resources"
robocopy "%WinPERoot%\x86\media\efi\boot" "%target%\media\efi\boot"
robocopy "%WinPERoot%\x86\media\efi\microsoft\boot" "%target%\media\efi\microsoft\boot"
ren      "%target%\media\EFI\Microsoft\boot\memtest.efi" memtest_x86.efi
robocopy "%WinPERoot%\amd64\media" "%target%\media"
robocopy "%WinPERoot%\amd64\media\efi\boot" "%target%\media\efi\boot"
robocopy "%WinPERoot%\amd64\media\efi\boot\en-us" "%target%\media\efi\boot\en-us"
robocopy "%WinPERoot%\amd64\media\efi\boot\%lang%" "%target%\media\efi\boot\%lang%" >nul 2>&1
robocopy "%WinPERoot%\amd64\media\efi\microsoft\boot" "%target%\media\efi\microsoft\boot"
robocopy "%WinPERoot%\amd64\media\efi\microsoft\boot\en-us" "%target%\media\efi\microsoft\boot\en-us"
robocopy "%WinPERoot%\amd64\media\efi\microsoft\boot\%lang%" "%target%\media\efi\microsoft\boot\%lang%"
robocopy "%WinPERoot%\amd64\media\efi\microsoft\boot\fonts" "%target%\media\efi\microsoft\boot\fonts"
robocopy "%WinPERoot%\amd64\media\efi\microsoft\boot\resources" "%target%\media\efi\microsoft\boot\resources"
::
md "%target%\media\sources"
::
md "%target%\mount"
::
echo.
echo ************************************************************
echo * Create Boot.wim 32 bits                                  *
echo ************************************************************
echo.
call :processwinpe x86
::
echo.
echo ************************************************************
echo * Create Boot.wim 64 bits                                  *
echo ************************************************************
echo.
call :processwinpe amd64
::
echo.
echo.
echo ***************************************************************
echo * Modify BCD so it contains bothboot_x86.wim and boot_x64.wim *
echo ***************************************************************
echo.
echo BCD Bios for x64 and x86
echo.
set "bcdstore=%target%\media\Boot\BCD"
bcdedit /store "%bcdstore%" /set {bootmgr} displaybootmenu yes
bcdedit /store "%bcdstore%" /set {bootmgr} locale %lang%
bcdedit /store "%bcdstore%" /deletevalue {bootmgr} toolsdisplayorder
rem    Get ramdisk guid
for /f "tokens=2 delims=," %%A in ('bcdedit /store "%bcdstore%" /enum ^| find /i "osdevice"') do set ramdiskguid=%%A
rem Modify the x64 boot entry
bcdedit /store "%bcdstore%" /set {default} device ramdisk=[boot]\sources\boot_x64.wim,%ramdiskguid%
bcdedit /store "%bcdstore%" /set {default} osdevice ramdisk=[boot]\sources\boot_x64.wim,%ramdiskguid%
bcdedit /store "%bcdstore%" /set {default} description "%WinPE% x64 bios"
bcdedit /store "%bcdstore%" /set {default} locale %lang%
bcdedit /store "%bcdstore%" /set {default} bootmenupolicy Legacy
rem    Create a x86 boot entry by making a copy of the x64 entry
for /f "tokens=7 delims=. " %%A in ('bcdedit /store "%bcdstore%" /copy {default} /d "%WinPE% x86 bios"') do set x86guid=%%A
bcdedit /store "%bcdstore%" /set %x86guid% device ramdisk=[boot]\sources\boot_x86.wim,%ramdiskguid%
bcdedit /store "%bcdstore%" /set %x86guid% osdevice ramdisk=[boot]\sources\boot_x86.wim,%ramdiskguid%
rem Create a boot entry for memory test
for /f "tokens=2 delims={}" %%a in ('bcdedit /store "%bcdstore%" /create /d "Memory Test" /application osloader') do set bcdentry={%%a}
bcdedit /store "%bcdstore%" /set %bcdentry% device boot
bcdedit /store "%bcdstore%" /set %bcdentry% path \boot\memtest.exe
bcdedit /store "%bcdstore%" /set %bcdentry% locale %lang%
bcdedit /store "%bcdstore%" /set %bcdentry% nointegritychecks Yes
bcdedit /store "%bcdstore%" /displayorder %bcdentry% /addlast
del /A "%target%\media\Boot\BCD.log?"
rem efi
echo.
echo BCD EFI for x64 and x86
echo.
set "bcdstore=%target%\media\EFI\Microsoft\Boot\BCD"
rem bcdedit /store "%bcdstore%" /set {bootmgr} locale %lang%
bcdedit /store "%bcdstore%" /set {bootmgr} displaybootmenu yes
bcdedit /store "%bcdstore%" /set {bootmgr} locale %lang%
bcdedit /store "%bcdstore%" /deletevalue {bootmgr} toolsdisplayorder
rem    Get ramdisk guid
for /f "tokens=2 delims=," %%A in ('bcdedit /store "%bcdstore%" /enum ^| find /i "osdevice"') do set ramdiskguid=%%A
rem Modify the x64 boot entry
bcdedit /store "%bcdstore%" /set {default} device ramdisk=[boot]\sources\boot_x64.wim,%ramdiskguid%
bcdedit /store "%bcdstore%" /set {default} osdevice ramdisk=[boot]\sources\boot_x64.wim,%ramdiskguid%
bcdedit /store "%bcdstore%" /set {default} description "%WinPE% x64 efi"
bcdedit /store "%bcdstore%" /set {default} locale %lang%
bcdedit /store "%bcdstore%" /set {default} bootmenupolicy Legacy
rem Create a boot entry for memory test
for /f "tokens=2 delims={}" %%a in ('bcdedit /store "%bcdstore%" /create /d "Memory Test EFI x64" /application osloader') do set bcdentry={%%a}
bcdedit /store "%bcdstore%" /set %bcdentry% device boot
bcdedit /store "%bcdstore%" /set %bcdentry% path \EFI\Microsoft\Boot\memtest.efi
bcdedit /store "%bcdstore%" /set %bcdentry% locale %lang%
bcdedit /store "%bcdstore%" /set %bcdentry% nointegritychecks Yes
bcdedit /store "%bcdstore%" /displayorder %bcdentry% /addlast
del /A "%target%\media\EFI\Microsoft\Boot\BCD.log?"
rem
echo.
echo.
echo ************************************************************
Echo * Create iso image                                         *
echo ************************************************************
echo.
::    Boot possible en BIOS (x86 et x6 et UEFI (X64 uniquement)
oscdimg.exe -bootdata:2#p0,e,b"%OSCDImgRoot%\etfsboot.com"#pEF,e,b"%OSCDImgRoot%\efisys_noprompt.bin" -h -u2 -m -o -l"%WinPE%" "%target%\media" "%target%\%WinPE%.iso"
::
echo.
echo ************************************************************
Echo * Create optional USB key                                  *
echo ************************************************************
echo.
set /p Driveletter=If you want to create a USB key, enter its drive letter ? :^>
if "%Driveletter%X"=="X" goto USB_End
if "%Driveletter:~-1%"==":" set "Driveletter=%Driveletter:~0,-1%"
set "Driveletter=%Driveletter%:"
echo %Driveletter%| findstr /B /E /I "[A-Z]:" >NUL
if errorlevel 1 goto USB_End
(
echo select volume=%Driveletter%
echo format fs=fat32 label="WinPE" quick
echo active
)|diskpart
bootsect.exe /nt60 %Driveletter% /force /mbr >NUL
robocopy "%target%\media" %Driveletter% /e
:USB_End
goto :term
::
echo.
echo ************************************************************
Echo * Update boot.wim                                          *
echo ************************************************************
echo.
:processwinpe
set "arch=%1"
echo.
echo Mount boot.wim image
copy "%WinPERoot%\%arch%\en-us\winpe.wim" "%target%\media\sources\boot.wim"
dism /Mount-Image /ImageFile:"%target%\media\sources\boot.wim" /index:1 /MountDir:"%target%\mount"
echo.
if /I %lang%==en-US goto EndLang
echo Get the en-US language pack name
for /f "tokens=4" %%a in ('dism /english /Image:"%target%\mount" /Get-Packages ^| findstr /i "LanguagePack"') do set langpkg=%%a
echo.
echo Add %lang% language pack
dism /Image:"%target%\mount" /Add-Package /PackagePath:"%WinPERoot%\%arch%\WinPE_OCs\%lang%\lp.cab"
Dism  /Image:"%target%\mount" /Set-AllIntl:%lang%
echo.
echo Remove en-US language pack
dism /Image:"%target%\mount" /Remove-Package /PackageName:%langpkg%
:EndLang
echo.
echo Unmount the image
dism /Unmount-Image /MountDir:"%target%\mount" /commit
echo.
dism /export-image /sourceimagefile:"%target%\media\sources\boot.wim" /sourceindex:1 /DestinationImageFile:"%target%\media\sources\boot_x%arch:~-2%.wim" /Compress:max
del "%target%\media\sources\boot.wim"
exit /b
::
echo.
echo ************************************************************
Echo * Exit                                                     *
echo ************************************************************
echo.
:term
rd /s /q "%target%\media"
rd /s /q "%target%\mount"   
echo End of process
rem chcp 850 >nul 2>&1
pause
