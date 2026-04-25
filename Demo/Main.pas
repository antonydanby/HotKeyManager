unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, 
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, 
  HotKeyManager;

type
  TMainForm = class(TForm)
    MemoLog: TMemo;
    ButtonRegister: TButton;
    ButtonUnregister: TButton;
    ButtonAssign: TButton;

    // Our instance of HKM. We can do this without
    // dropping a component on the form if needed
    HotKeyManager: THotKeyManager;

    procedure FormCreate(Sender: TObject);
    procedure ButtonRegisterClick(Sender: TObject);
    procedure ButtonUnregisterClick(Sender: TObject);
    procedure ButtonAssignClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    // HotKeyManager Events
    procedure HotKeyManagerNotify(Sender: TObject; const HotKey: THotKeyRecord);
    procedure HotKeyManagerKeyCaptured(Sender: TObject; Modifiers: THKModifiers; VirtualKey: Word);
  private
    fCurrentID: Integer;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // CRITICAL: Allow the Form to intercept keys before they hit controls
  Self.KeyPreview := True;
end;

procedure TMainForm.ButtonAssignClick(Sender: TObject);
begin
  MemoLog.Lines.Add('>>> PRESS YOUR DESIRED HOTKEY COMBINATION NOW...');
  HotKeyManager.StartCapture;
  // Ensure the form is ready to receive input
  Self.SetFocus;
end;

procedure TMainForm.HotKeyManagerNotify(Sender: TObject; const HotKey: THotKeyRecord);
begin
  MemoLog.Lines.Add('GLOBAL HOTKEY DETECTED: ' + HotKey.ToKeyString);
end;

procedure TMainForm.HotKeyManagerKeyCaptured(Sender: TObject; Modifiers: THKModifiers; VirtualKey: Word);
var
  TempRec: THotKeyRecord;
begin
  // We use our helper to show what was captured
  TempRec.Modifiers := 0;
  if hmControl in Modifiers then TempRec.Modifiers := TempRec.Modifiers or MOD_CONTROL;
  if hmShift in Modifiers then TempRec.Modifiers := TempRec.Modifiers or MOD_SHIFT;
  if hmAlt in Modifiers then TempRec.Modifiers := TempRec.Modifiers or MOD_ALT;
  if hmWin in Modifiers then TempRec.Modifiers := TempRec.Modifiers or MOD_WIN;
  TempRec.VirtualKey := VirtualKey;

  MemoLog.Lines.Add('Captured: ' + TempRec.ToKeyString);

  // Automatically register it!
  try
    if fCurrentID <> 0 then HotKeyManager.Unregister(fCurrentID);

    fCurrentID := HotKeyManager.Register(Modifiers, VirtualKey, True);
    MemoLog.Lines.Add('SUCCESS: "' + TempRec.ToKeyString + '" is now your active Hotkey.');
    ButtonUnregister.Enabled := True;
  except
    on E: Exception do ShowMessage(E.Message);
  end;
end;

procedure TMainForm.ButtonRegisterClick(Sender: TObject);
begin
  // Hardcoded example
  try
    fCurrentID := HotKeyManager.Register([hmControl, hmAlt], VK_F8, True);
    MemoLog.Lines.Add('Registered Ctrl+Alt+F8');
  except
    on E: Exception do MemoLog.Lines.Add(E.Message);
  end;
end;

procedure TMainForm.ButtonUnregisterClick(Sender: TObject);
begin
  HotKeyManager.UnregisterAll;
  fCurrentID := 0;
  MemoLog.Lines.Add('All hotkeys cleared.');
  ButtonUnregister.Enabled := False;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift:TShiftState);
var
  Mods: THKModifiers;
begin
  // If we are in capture mode, intercept the key and tell the manager
  if HotKeyManager.IsCapturing then
  begin
    Mods := [];
    if ssCtrl in Shift then Include(Mods, hmControl);
    if ssShift in Shift then Include(Mods, hmShift);
    if ssAlt in Shift then Include(Mods, hmAlt);
    // Note: Windows Key (ssLeft/ssRight) is trickier in TShiftState
    // but usually handled via GetKeyState in the manager if needed.

    // Manually trigger the capture logic
    HotKeyManager.StopCapture;
    HotKeyManagerKeyCaptured(HotKeyManager, Mods, Key);

    // Set Key to 0 so the Memo or Buttons don't process the keypress
    Key := 0;
  end;
end;

end.