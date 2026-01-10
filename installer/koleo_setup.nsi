!include "MUI2.nsh"
!include "FileFunc.nsh"

Name "Koleo Browser"
OutFile "..\build\installer\KoleoBrowserSetup.exe"
InstallDir "$PROGRAMFILES\Koleo Browser"
RequestExecutionLevel admin

!define MUI_ABORTWARNING
!define MUI_ICON "..\assets\logo\koleo_logo.ico"

; Finish page - run app after install
!define MUI_FINISHPAGE_RUN "$INSTDIR\koleo_browser.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Запустить Koleo Browser"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "Russian"

; Silent install with auto-launch support
Function .onInit
    ${GetParameters} $R0
    ${GetOptions} $R0 "/LAUNCH" $R1
    IfErrors +2 0
    StrCpy $R9 "1" ; Flag to launch after install
FunctionEnd

Section "Install"
    SetOutPath "$INSTDIR"
    File /r "..\build\windows\x64\runner\Release\*.*"
    
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    CreateShortcut "$DESKTOP\Koleo Browser.lnk" "$INSTDIR\koleo_browser.exe"
    CreateDirectory "$SMPROGRAMS\Koleo Browser"
    CreateShortcut "$SMPROGRAMS\Koleo Browser\Koleo Browser.lnk" "$INSTDIR\koleo_browser.exe"
    CreateShortcut "$SMPROGRAMS\Koleo Browser\Удалить.lnk" "$INSTDIR\uninstall.exe"
    
    ; Uninstall info
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KoleoBrowser" "DisplayName" "Koleo Browser"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KoleoBrowser" "UninstallString" "$INSTDIR\uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KoleoBrowser" "DisplayIcon" "$INSTDIR\koleo_browser.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KoleoBrowser" "Publisher" "Koleo"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KoleoBrowser" "DisplayVersion" "1.0.0"
    
    ; Register as browser
    WriteRegStr HKLM "Software\Clients\StartMenuInternet\KoleoBrowser" "" "Koleo Browser"
    WriteRegStr HKLM "Software\Clients\StartMenuInternet\KoleoBrowser\Capabilities" "ApplicationName" "Koleo Browser"
    WriteRegStr HKLM "Software\Clients\StartMenuInternet\KoleoBrowser\Capabilities" "ApplicationDescription" "Быстрый и современный браузер"
    WriteRegStr HKLM "Software\Clients\StartMenuInternet\KoleoBrowser\Capabilities\StartMenu" "StartMenuInternet" "Koleo Browser"
    WriteRegStr HKLM "Software\Clients\StartMenuInternet\KoleoBrowser\Capabilities\URLAssociations" "http" "KoleoBrowserURL"
    WriteRegStr HKLM "Software\Clients\StartMenuInternet\KoleoBrowser\Capabilities\URLAssociations" "https" "KoleoBrowserURL"
    WriteRegStr HKLM "Software\Clients\StartMenuInternet\KoleoBrowser\DefaultIcon" "" "$INSTDIR\koleo_browser.exe,0"
    WriteRegStr HKLM "Software\Clients\StartMenuInternet\KoleoBrowser\shell\open\command" "" '"$INSTDIR\koleo_browser.exe"'
    
    ; Register URL handler
    WriteRegStr HKLM "Software\Classes\KoleoBrowserURL" "" "Koleo Browser URL"
    WriteRegStr HKLM "Software\Classes\KoleoBrowserURL" "URL Protocol" ""
    WriteRegStr HKLM "Software\Classes\KoleoBrowserURL\DefaultIcon" "" "$INSTDIR\koleo_browser.exe,0"
    WriteRegStr HKLM "Software\Classes\KoleoBrowserURL\shell\open\command" "" '"$INSTDIR\koleo_browser.exe" "%1"'
    
    ; Register in RegisteredApplications
    WriteRegStr HKLM "Software\RegisteredApplications" "Koleo Browser" "Software\Clients\StartMenuInternet\KoleoBrowser\Capabilities"
    
    ; Auto-launch after silent install
    IfSilent 0 +3
    StrCmp $R9 "1" 0 +2
    Exec "$INSTDIR\koleo_browser.exe"
SectionEnd

Section "Uninstall"
    RMDir /r "$INSTDIR"
    Delete "$DESKTOP\Koleo Browser.lnk"
    RMDir /r "$SMPROGRAMS\Koleo Browser"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KoleoBrowser"
    DeleteRegKey HKLM "Software\Clients\StartMenuInternet\KoleoBrowser"
    DeleteRegKey HKLM "Software\Classes\KoleoBrowserURL"
    DeleteRegValue HKLM "Software\RegisteredApplications" "Koleo Browser"
SectionEnd
