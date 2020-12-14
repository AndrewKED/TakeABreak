#define MyAppName "Take A Break"
#define MyAppVersion "1.3.0"
#define Year "2020"
#define MyAppPublisher "Answer Systems"

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
;AppPublisherURL=https://www.intermet.co
AppContact=Customer Support Department
AppCopyright=Copyright (C) (#Year) {#MyAppPublisher}
AppSupportPhone=+27 21 532 2351
;AppSupportURL=https://www.intermet.co
;AppUpdatesURL=https://www.intermet.co
DefaultDirName={commonpf}\AnswerSystems\TakeABreak
DefaultGroupName="Answer Systems\Take A Break"
DisableProgramGroupPage=yes
DisableWelcomePage=no
OutputDir=..\Installations
OutputBaseFilename=BreakSetup_x-x-x_(32)
SolidCompression=yes
SourceDir=InstallationFiles
SetupIconFile="TakeABreak_Icon.ico"
UninstallDisplayIcon={app}\TakeABreak.exe
UninstallDisplayName={#MyAppName}
Uninstallable=True
;WizardImageFile="Supplementary Files\Side Splash only - InterMet Logo + fade2.bmp"
;WizardSmallImageFile="Supplementary Files\Banner - InterMet Logo Top Right.bmp"

[Files]
Source: "TakeABreak.exe"; DestDir: "{app}"

[Icons]
Name: "{group}\Take A Break"; Filename: "{app}\TakeABreak.exe"; Comment: "Prompt to regularly break from computer/desk work";
Name: "{commonstartup}\Take A Break"; Filename: "{app}\TakeABreak.exe"; Comment: "Prompt to regularly break from computer/desk work";
