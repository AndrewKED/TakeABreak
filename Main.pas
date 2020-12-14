unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Spin, Buttons;

type
  TForm1 = class(TForm)
    Image1: TImage;
    bbTaken: TBitBtn;
    Label1: TLabel;
    seMinutes: TSpinEdit;
    Label2: TLabel;
    Timer1: TTimer;
    lNextBreak: TLabel;
    lBreakTime: TLabel;
    lBreakTimeTitle: TLabel;
    bbTaking: TBitBtn;
    procedure bbTakenClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bbTakingClick(Sender: TObject);
    procedure seMinutesChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  App_Ops;

var
  countDown : Integer;
  timerBreak : Integer;

{$R *.dfm}


//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Windows 98/2000 doesn't want to foreground a window when
//              some other window has the keyboard focus.
//              ForceForegroundWindow is an enhanced SetForeGroundWindow/bringtofront
//              function to bring a window to the front.
//
//  Manchmal funktioniert die SetForeGroundWindow Funktion
//  nicht so, wie sie sollte; besonders unter Windows 98/2000,
//  wenn ein anderes Fenster den Fokus hat.
//  ForceForegroundWindow ist eine "verbesserte" Version von
//  der SetForeGroundWindow API-Funktion, um ein Fenster in
//  den Vordergrund zu bringen.
//
// http://www.swissdelphicenter.ch/torry/showcode.php?id=261
//
//  UPDATED   :
//
//***************************************************************************
function ForceForegroundWindow(hwnd: THandle): Boolean;
const
  SPI_GETFOREGROUNDLOCKTIMEOUT = $2000;
  SPI_SETFOREGROUNDLOCKTIMEOUT = $2001;
var
  ForegroundThreadID: DWORD;
  ThisThreadID: DWORD;
  timeout: DWORD;
begin
  if IsIconic(hwnd) then ShowWindow(hwnd, SW_RESTORE);

  if GetForegroundWindow = hwnd then Result := True
  else
  begin
    // Windows 98/2000 doesn't want to foreground a window when some other
    // window has keyboard focus

    if ((Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion > 4)) or
      ((Win32Platform = VER_PLATFORM_WIN32_WINDOWS) and
      ((Win32MajorVersion > 4) or ((Win32MajorVersion = 4) and
      (Win32MinorVersion > 0)))) then
    begin
      // Code from Karl E. Peterson, www.mvps.org/vb/sample.htm
      // Converted to Delphi by Ray Lischner
      // Published in The Delphi Magazine 55, page 16

      Result := False;
      ForegroundThreadID := GetWindowThreadProcessID(GetForegroundWindow, nil);
      ThisThreadID := GetWindowThreadPRocessId(hwnd, nil);
      if AttachThreadInput(ThisThreadID, ForegroundThreadID, True) then
      begin
        BringWindowToTop(hwnd); // IE 5.5 related hack
        SetForegroundWindow(hwnd);
        AttachThreadInput(ThisThreadID, ForegroundThreadID, False);
        Result := (GetForegroundWindow = hwnd);
      end;
      if not Result then
      begin
        // Code by Daniel P. Stasinski
        SystemParametersInfo(SPI_GETFOREGROUNDLOCKTIMEOUT, 0, @timeout, 0);
        SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(0),
          SPIF_SENDCHANGE);
        BringWindowToTop(hwnd); // IE 5.5 related hack
        SetForegroundWindow(hWnd);
        SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(timeout), SPIF_SENDCHANGE);
      end;
    end
    else
    begin
      BringWindowToTop(hwnd); // IE 5.5 related hack
      SetForegroundWindow(hwnd);
    end;

    Result := (GetForegroundWindow = hwnd);
  end;
end; // ForceForegroundWindow

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure TForm1.bbTakenClick(Sender: TObject);
begin
  bbTaken.Enabled := FALSE;
  bbTaking.Enabled := FALSE;

  countDown := seMinutes.Value * 60;

  lBreakTime.Visible := FALSE;
  lBreakTimeTitle.Visible := FALSE;

  WindowState := wsMinimized;
end;

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure TForm1.bbTakingClick(Sender: TObject);
begin
  bbTaking.Enabled := FALSE;

  timerBreak := 0;
  lBreakTime.Visible := TRUE;
  lBreakTimeTitle.Visible := TRUE;
end;

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure TForm1.FormActivate(Sender: TObject);
begin
  WindowState := wsMinimized;
end;

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := Caption + ' v' + GetApplicationVersion;

  countDown := seMinutes.Value * 60;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ((bbTaking.Enabled) and
      (Key = VK_F1)) then
  begin
    bbTakingClick(Sender);
  end;

  if ((bbTaken.Enabled) and
      (Key = VK_F10)) then
  begin
    bbTakenClick(Sender);
  end;
end;

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure TForm1.seMinutesChange(Sender: TObject);
begin
  countDown := seMinutes.Value * 60;
end;

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Dec(countDown);

  if (countDown >= 0) then
  begin
    lNextBreak.Caption := 'Next break in ' + IntToStr(countDown div 60) + ' minutes';
  end // if
  else
  begin
    Inc(timerBreak);
  end;

  if (countDown = 0) then
  begin
    // Triggered!
    Beep;
    WindowState := wsNormal;
    ForceForegroundWindow(Application.Handle);
    bbTaken.Enabled := TRUE;
    bbTaking.Enabled := TRUE;
  end;

  // Once triggered, if exercise is nor tunning, every 30 seconds, beep and show again
  if ((countDown < -30) and
      (bbTaking.Enabled)) then
  begin
    countDown := 0;
    Beep;
    WindowState := wsNormal;
    ForceForegroundWindow(Application.Handle);
  end;

  lBreakTime.Caption := FormatDateTime('nn:ss', timerBreak/(24*60*60));
end;

end.
