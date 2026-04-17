unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Spin, Buttons;

type
  TForm1 = class(TForm)
    Image1: TImage;
    Timer1: TTimer;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    lNextBreak: TLabel;
    bbTaken: TBitBtn;
    seMinutes: TSpinEdit;
    bbTaking: TBitBtn;
    pBreakTime: TPanel;
    procedure bbTakenClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bbTakingClick(Sender: TObject);
    procedure seMinutesChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  System.DateUtils,
  App_Ops, Font_Ops;

const
  WARNING_SECONDS = 30;
  WARNING_BEEPS = 5;
  MIN_BREAK_TIME = 30;

type
  TState = (
    ST_IDLE,
    ST_TIME_TO_BREAK,
    ST_TAKING_BREAK
  );

var
  currentState : TState;
  countDown : Integer;
  timerBreak : Integer;
  numBeeps : Integer;

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
  if (timerBreak < 30) then
  begin
    Exit;
  end;

  bbTaken.Enabled := FALSE;
  bbTaking.Enabled := FALSE;
  currentState := ST_IDLE;

  countDown := seMinutes.Value * 60;

  pBreakTime.Visible := FALSE;

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
  bbTaken.Enabled := FALSE;

  currentState := ST_TAKING_BREAK;

  timerBreak := 0;
  pBreakTime.Caption := 'Break time';
  pBreakTime.Visible := TRUE;
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

  // First break in 20 minutes
  currentState := ST_IDLE;
  countdown := 20 * 60;
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
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caNone;
end;

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := Caption + ' v' + GetApplicationVersion;

  LoadResourceFont('FA6SOLID');

  bbTakenClick(Sender);
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
procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ((bbTaking.Enabled) and
      (Key = VK_F1)) then
  begin
    bbTakingClick(Sender);
  end; // if

  if ((bbTaken.Enabled) and
      (Key = VK_F10)) then
  begin
    bbTakenClick(Sender);
  end; // if
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
  case currentState of
    ST_TIME_TO_BREAK :
    begin
      // Count down the time during which the user does not respond, and take
      // a break (signalled by clicking on the bbTaking button)
      Dec(countDown);
      if (countDown <= 0) then
      begin
        // The user has taken too long to respond (> 30 seconds)

        // Bring the reminder to the foreground, in case they had ignored it.
        ForceForegroundWindow(Application.Handle);
        countDown := WARNING_SECONDS;

        if (numBeeps > 0) then
        begin
          // For the first few times that the user ignores the prompt to take
          // a break, sound a beep.
          Beep;
          Dec(numBeeps);
        end;
      end;
    end;

    ST_TAKING_BREAK :
    begin
      // Ensure that the screen stays in the foreground while taking the break.
      // This will force the user to stop whatever else they were doing
      ForceForegroundWindow(Application.Handle);
      Inc(timerBreak);
      if (timerBreak > MIN_BREAK_TIME) then
      begin
        bbTaken.Enabled := TRUE;
      end;
      pBreakTime.Caption := 'Break time = ' + FormatDateTime('nn:ss', timerBreak/(24*60*60));
    end // case

    else
    begin
      // ST_IDLE
      Dec(countDown);
      if (countDown > 0) then
      begin
        lNextBreak.Caption := 'Next break in ' + IntToStr(countDown div 60) + ' minutes';
      end // if
      else if (countDown <= 0) then
      begin
        // Triggered!
        Beep;

        WindowState := wsNormal;
        ForceForegroundWindow(Application.Handle);
        timerBreak := 0;
        bbTaking.Enabled := TRUE;
        bbTaken.Enabled := FALSE;
        bbTaking.SetFocus;
        currentState := ST_TIME_TO_BREAK;
        countDown := WARNING_SECONDS;
        numBeeps := WARNING_BEEPS;
      end
    end;
  end;
end;

end.
