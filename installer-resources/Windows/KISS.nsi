; Header for Modern UI
!include "MUI.nsh"

; Header for using RunningX64 macro
!include "x64.nsh"

; Define KIPR application name and version number
!define APP_NAME "KIPR Software Suite"
!define APP_MAJOR_VERSION "1"
!define APP_MINOR_VERSION "0"
!define BUILD_NUMBER "27"

; Standard Release app name and version
!define VERSION "${APP_MAJOR_VERSION}.${APP_MINOR_VERSION}.${BUILD_NUMBER}"
!define INSTALLER_FILENAME "KIPR-Software-Suite-${VERSION}"
!define APP_NAME_AND_VERSION "${APP_NAME} ${VERSION}"

; Ensure that directories have been defined
!ifndef DEPLOY_DIR
	!error "DEPLOY_DIR must be defined!"
!endif
!ifndef OUT_DIR
	!error "OUT_DIR must be defined!"
!endif

; Name of the installer
Name "${APP_NAME_AND_VERSION}"

; Path to final install directory
InstallDir "$PROGRAMFILES\${APP_NAME_AND_VERSION}"

; Path to the installer itself
OutFile "${OUT_DIR}\${INSTALLER_FILENAME}.exe"

; Modern interface settings
!define MUI_ICON "windows_icon.ico"
; !define MUI_ABORTWARNING
; !define MUI_FINISHPAGE_RUN "$INSTDIR\KISS\KISS.exe"
; !define MUI_FINISHPAGE_RUN_TEXT "Run KISS IDE now"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "License.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Set languages (first is default language)
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_RESERVEFILE_LANGDLL

Section "Daylite" DAYLITE
	; Set Section properties
	SetOverwrite on  ; overwrite existing files
	SectionIn RO     ; cannot be unchecked  
  	
	; Set MinGW Files	
	SetOutPath "$INSTDIR\prefix\"
	File /r "${DEPLOY_DIR}\prefix\*.*"
SectionEnd

Section "7-Zip" 7ZIP
	; Set Section properties
	SetOverwrite on  ; overwrite existing files
	SectionIn RO     ; cannot be unchecked  
  	
	; Set MinGW Files	
	SetOutPath "$INSTDIR\7-Zip\"
	File /r "${DEPLOY_DIR}\7-Zip\*.*"
SectionEnd

Section "NSSM" NSSM
	; Set Section properties
	SetOverwrite on  ; overwrite existing files
	SectionIn RO     ; cannot be unchecked  
  	
	; Set MinGW Files	
	SetOutPath "$INSTDIR\nssm\"
	File /r "${DEPLOY_DIR}\nssm\*.*"
SectionEnd

Section "KISS IDE" KISSIDE
	; Set Section properties
	SetOverwrite on  ; overwrite existing files
	SectionIn RO     ; cannot be unchecked  
  	
	; Set KISS Platform Files
	SetOutPath "$INSTDIR"
  File /r "${DEPLOY_DIR}\harrogate.zip"
	File "windows_icon.ico"
  File "run_harrogate.bat"
  File "start_browser.bat"
  File "KISS IDE.url"
	!define KISS_ICON "$INSTDIR\windows_icon.ico"

  nsExec::ExecToLog '"$INSTDIR\7-Zip\7za.exe" x "$OUTDIR\harrogate.zip"'
  
  ; nsExec::ExecToLog '"$INSTDIR\nssm\win32\nssm.exe" install harrogate "$INSTDIR\run_harrogate.bat"'
  
	; Set up start menu entry
	CreateDirectory "$SMPROGRAMS\${APP_NAME_AND_VERSION}"
	CreateShortCut "$SMPROGRAMS\${APP_NAME_AND_VERSION}\KISS IDE.lnk" "$INSTDIR\KISS IDE.url" "" ${KISS_ICON} 0
	CreateShortCut "$SMPROGRAMS\${APP_NAME_AND_VERSION}\Start KISS IDE Server.lnk" "$INSTDIR\run_harrogate.bat" "" ${KISS_ICON} 0

	; Set up desktop shortcut
	CreateShortCut "$DESKTOP\Start KISS IDE Server.lnk" "$INSTDIR\run_harrogate.bat" "" ${KISS_ICON} 0
SectionEnd

Section "MinGW" MinGW
	; Set Section properties
	SetOverwrite on  ; overwrite existing files
	SectionIn RO     ; cannot be unchecked  
  	
	; Set MinGW Files	
	SetOutPath "$INSTDIR\MinGW\"
	File /r "${DEPLOY_DIR}\MinGW\*.*"
SectionEnd

Section "Visual C++ Redistributable 2013" VCRedist2013
	SetOutPath $INSTDIR
    File "vcredist_x86.exe"
    ExecWait "$INSTDIR\vcredist_x86.exe"
SectionEnd

Section "Visual C++ Redistributable 2012" VCRedist2012
	SetOutPath $INSTDIR
    File "vcredist_x86_2012.exe"
    ExecWait "$INSTDIR\vcredist_x86_2012.exe"
SectionEnd

Section "Visual C++ Redistributable 2010" VCRedist2010
	SetOutPath $INSTDIR
    File "vcredist_x86_2010.exe"
    ExecWait "$INSTDIR\vcredist_x86_2010.exe"
SectionEnd

Section -FinishSection
	WriteRegStr HKLM "Software\${APP_NAME_AND_VERSION}" "" "$INSTDIR"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_AND_VERSION}" "DisplayName" "${APP_NAME_AND_VERSION}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_AND_VERSION}" "UninstallString" "$INSTDIR\uninstall.exe"
	WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

; Modern install component descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
!insertmacro MUI_DESCRIPTION_TEXT ${VCRedist2013} "Visual C++ Redistributable for Visual Studio 2013"
!insertmacro MUI_DESCRIPTION_TEXT ${VCRedist2012} "Visual C++ Redistributable for Visual Studio 2012 Update 3"
!insertmacro MUI_DESCRIPTION_TEXT ${VCRedist2010} "Visual C++ Redistributable for Visual Studio 2010"
!insertmacro MUI_DESCRIPTION_TEXT ${DAYLITE} "KIPR's Communication Backbone"
!insertmacro MUI_DESCRIPTION_TEXT ${KISSIDE} "KIPR's Instructional Software System IDE"
!insertmacro MUI_DESCRIPTION_TEXT ${7ZIP} "7-Zip File Archiver"
!insertmacro MUI_DESCRIPTION_TEXT ${NSSM} "Non-Sucking Service Manager"
!insertmacro MUI_DESCRIPTION_TEXT ${MinGW} "Minimalist GNU for Windows"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Uninstall section
Section Uninstall
  ;uninstall service
  ; nsExec::ExecToLog '"$INSTDIR\nssm\win32\nssm.exe" remove harrogate'
  
	; Remove keys from registry
	; DeleteRegKey HKLM "SOFTWARE\${APP_NAME_AND_VERSION}"
	; DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME_AND_VERSION}"

	; Delete the uninstaller itself
	Delete "$INSTDIR\uninstall.exe"

	; Delete start menu entires and desktop shortcuts
	Delete "$DESKTOP\KISS IDE.lnk"
	Delete "$DESKTOP\Start KISS IDE Server.lnk"
	Delete "$SMPROGRAMS\${APP_NAME_AND_VERSION}\Start KISS IDE Server.lnk"
	RMDir  "$SMPROGRAMS\${APP_NAME_AND_VERSION}"

	; Delete the entire install directory
	RMDir /r "$INSTDIR\"
  
  MessageBox MB_OK "Unable remove all folders. Please delete $INSTDIR manually"
  
SectionEnd

BrandingText "KISS Institute For Practical Robotics"