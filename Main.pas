unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Spin, Buttons;

type
  TfMain = class(TForm)
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
    lState: TLabel;
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
    procedure ResetForPCActiveState;
    procedure TakingABreak;
  public
    { Public declarations }
  end;

var
  fMain: TfMain;

implementation

uses
  System.DateUtils, System.Math,
  App_Ops, Font_Ops;

const
  PROGRAM_NAME = 'Take A Break';

  WARNING_SECONDS = 30;
  WARNING_BEEPS = 5;
  MINIMUM_BREAK_SECONDS = 30;
  PC_USER_IS_IDLE_MINUTES = 10;   // If no mouse/keyboard in 10 minutes, user is considered to be taking a break.

type
  TState = (
    ST_IDLE_PC_IN_USE,
    ST_IDLE_PC_UNATTENDED,
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
//  OPERATION : Set controls and application to idle conditions, as required
//              to start timeout.
//
//              The state is not changed i.e. the user may/may not be using the PC
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
procedure TfMain.ResetForPCActiveState;
begin
  bbTaken.Enabled := FALSE;
  bbTaking.Enabled := FALSE;

  countDown := seMinutes.Value * 60;

  pBreakTime.Visible := FALSE;

  WindowState := wsMinimized;
end; // ResetForPCActiveState

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
procedure TfMain.bbTakenClick(Sender: TObject);
begin
  if (timerBreak < MINIMUM_BREAK_SECONDS) then
  begin
    // Once triggered, the break period must be a certain minimum time
    Exit;
  end;

  currentState := ST_IDLE_PC_IN_USE;
  ResetForPCActiveState;
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
procedure TfMain.bbTakingClick(Sender: TObject);
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
procedure TfMain.FormActivate(Sender: TObject);
begin
  currentState := ST_IDLE_PC_IN_USE;
  ResetForPCActiveState;
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
procedure TfMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MessageDlg(
    'To keep this reminder running, rather than closing it,' + sLineBreak +
    'an hour will be added to the current working time.',
    mtInformation, [mbOK], 0
  );
  ResetForPCActiveState;
  Inc(countdown, 60 * 60);
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
procedure TfMain.FormCreate(Sender: TObject);
begin
  Caption := PROGRAM_NAME + ' v' + GetApplicationVersion;

  LoadResourceFont('FA6SOLID');

  // The maximum working time will not be remembered between sessions.
  // 20 minutes of working is considered a reasonable fixed value to make constant.
  seMinutes.Value := 20;
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
procedure TfMain.FormKeyDown(Sender: TObject; var Key: Word;
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
procedure TfMain.seMinutesChange(Sender: TObject);
begin
  countDown := seMinutes.Value * 60;
end;

//***************************************************************************
//
//  OPERATION : The user has clicked the "Break" button to acknowledge that
//              they are now taking a break.
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
procedure TfMain.TakingABreak;
begin
  Inc(timerBreak);
  pBreakTime.Caption := 'Break time = ' + FormatDateTime('nn:ss', timerBreak/(24*60*60));

  if (timerBreak mod 15 = 0) then
  begin
    // Pop the screen to foreground every 15 seconds while taking the break.
    // This will encourage the user to get away from in front of
    // the computer, and actually take the break!
    ForceForegroundWindow(Application.Handle);
  end;

  if (not bbTaken.Enabled) then
  begin
    // The minimum break time has not yet been recorded
    if (timerBreak >= MINIMUM_BREAK_SECONDS) then
    begin
      // The minimum break time has now been achieved.
      // Allow the user to resume working.
      bbTaken.Enabled := TRUE;
      // This beep is to inform someone who might have stepped away from
      // their PC, that they can come back now.
      Beep;
    end // if
    else
    begin
      // The user is meant to be taking the break now.
      if (MillisecondsSinceKbdMouse > 1000) then
      begin
        // There is no keyboard/mouse activity.
        lState.Caption := 'The user has left the mouse/keyboard.';
      end // if
      else
      begin
        // User is actually NOT taking a break!
        // Punish them by restarting the break timer.
        timerBreak := 0;
        lState.Caption := 'You said you were taking a break!';
      end;
    end // else
  end // if
  else
  begin
    // The user is allowed to resume working again
    if (MillisecondsSinceKbdMouse < 2 * Timer1.Interval) then
    begin
      // The PC was idle for a suitable period of time, and is active
      // again. Auto-click the "Resume working" button.
      bbTakenClick(nil);
    end;
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
procedure TfMain.Timer1Timer(Sender: TObject);
begin
  if (MillisecondsSinceKbdMouse > PC_USER_IS_IDLE_MINUTES * 60 * 1000) then
  begin
    // Irrespective of the current state, if there has been no mouse/keyboard
    // activity on the PC for some minutes, assume that the computer user is
    // taking some form of a break.
    currentState := ST_IDLE_PC_UNATTENDED;
    ResetForPCActiveState;
  end;

  case currentState of
    ST_TIME_TO_BREAK :
    begin
      lState.Caption := 'Waiting for user to agree to take a break';
      // Count down the time during which the user does not respond, and take
      // a break (signalled by clicking on the "now taking a break" button)
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
    end; // case

    ST_TAKING_BREAK :
    begin
      TakingABreak;
    end; // case

    ST_IDLE_PC_UNATTENDED :
    begin
      lState.Caption := 'PC appears to be unattended';
      // The PC is considered to be unattended
      if (MillisecondsSinceKbdMouse < Timer1.Interval * 10) then
      begin
        // The mouse or keyboard has recently been in use.
        // The PC user is considered to have returned to the PC (from being away)

        // Restart the operations
        currentState := ST_IDLE_PC_IN_USE;
        ResetForPCActiveState;
      end;
    end;

    else
    begin
      lState.Caption := Format(
        'PC is in use. Last activity %d seconds ago',
        [MillisecondsSinceKbdMouse div 1000]
      );
      // ST_IDLE_PC_IN_USE
      currentState := ST_IDLE_PC_IN_USE;

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

  // Only permit changing of the inter-break time during PC usage time (outside
  // of the break time).
  // If enabled during a break, it has occasionally been (inadvertently?) cleared,
  // resulting in a very short break repeat time.
  seMinutes.Enabled := (currentState = ST_IDLE_PC_IN_USE);
end;

end.
