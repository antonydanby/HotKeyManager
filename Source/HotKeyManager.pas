unit HotKeyManager;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, Winapi.Windows, Winapi.Messages;

type
  EHotKeyError = class(Exception);

  THKModifier = (hmControl, hmShift, hmAlt, hmWin);
  THKModifiers = set of THKModifier;

  THotKeyRecord = record
    KeyID: Integer;
    VirtualKey: Word;
    Modifiers: Word;
    function ToKeyString: string;
  end;

  THotKeyNotifyEvent = procedure(Sender: TObject; const HotKey: THotKeyRecord) of object;
  TKeyCapturedEvent = procedure(Sender: TObject; Modifiers: THKModifiers; VirtualKey: Word) of object;

  THotKeyManager = class(TComponent)
  private
    fHandle: HWND;
    fHotKeys: TDictionary<Integer, THotKeyRecord>;
    fNextHotKeyID: Integer;
    fOnHotKey: THotKeyNotifyEvent;
    fOnKeyCaptured: TKeyCapturedEvent;
    fIsCapturing: Boolean;
    procedure WndProc(var Message: TMessage);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Register(Modifiers: Word; VirtualKey: Word; RaiseOnError: Boolean = False): Integer; overload;
    function Register(Modifiers: THKModifiers; VirtualKey: Word; RaiseOnError: Boolean = False): Integer; overload;
    function Unregister(HotKeyID: Integer): Boolean;
    procedure UnregisterAll;

    // Put the manager into capture mode
    procedure StartCapture;
    procedure StopCapture;

    property IsCapturing: Boolean read FIsCapturing;
  published
    property OnHotKey: THotKeyNotifyEvent read FOnHotKey write FOnHotKey;
    property OnKeyCaptured: TKeyCapturedEvent read FOnKeyCaptured write FOnKeyCaptured;
  end;

const
  KEY_CONTROL = MOD_CONTROL;
  KEY_SHIFT   = MOD_SHIFT;
  KEY_ALT     = MOD_ALT;
  KEY_WIN     = MOD_WIN;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('l53n', [THotKeyManager]);
end;

{ THotKeyRecord }

function THotKeyRecord.ToKeyString: string;
var
  LKeyName: array[0..255] of Char;
  LScanCode: LongWord;
begin
  Result := '';
  if (Modifiers and MOD_CONTROL) <> 0 then Result := Result + 'Ctrl+';
  if (Modifiers and MOD_SHIFT) <> 0 then Result := Result + 'Shift+';
  if (Modifiers and MOD_ALT) <> 0 then Result := Result + 'Alt+';
  if (Modifiers and MOD_WIN) <> 0 then Result := Result + 'Win+';

  LScanCode := MapVirtualKey(VirtualKey, 0) shl 16;
  if GetKeyNameText(LScanCode, LKeyName, 256) > 0 then
    Result := Result + LKeyName
  else
    Result := Result + 'Key_' + IntToStr(VirtualKey);
end;

{ THotKeyManager }

constructor THotKeyManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fHotKeys := TDictionary<Integer, THotKeyRecord>.Create;
  fNextHotKeyID := 1000;
  fHandle := AllocateHWnd(WndProc);
  fIsCapturing := False;
end;

destructor THotKeyManager.Destroy;
begin
  UnregisterAll;
  DeallocateHWnd(fHandle);
  FHotKeys.Free;
  inherited Destroy;
end;

procedure THotKeyManager.StartCapture;
begin
  fIsCapturing := True;
end;

procedure THotKeyManager.StopCapture;
begin
  FIsCapturing := False;
end;

procedure THotKeyManager.WndProc(var Message: TMessage);
var
  HotKeyRec: THotKeyRecord;
  Mods: THKModifiers;
  VKey: Word;
begin
  // While capturing, we watch for KeyDown events on our hidden handle
  if fIsCapturing and ((Message.Msg = WM_KEYDOWN) or (Message.Msg = WM_SYSKEYDOWN)) then
  begin
    VKey := Message.WParam;
    
    // Ignore stand-alone modifier presses
    if not (VKey in [VK_CONTROL, VK_SHIFT, VK_MENU, VK_LWIN, VK_RWIN]) then
    begin
      Mods := [];
      if GetKeyState(VK_CONTROL) < 0 then Include(Mods, hmControl);
      if GetKeyState(VK_SHIFT) < 0 then Include(Mods, hmShift);
      if GetKeyState(VK_MENU) < 0 then Include(Mods, hmAlt);
      if (GetKeyState(VK_LWIN) < 0) or (GetKeyState(VK_RWIN) < 0) then Include(Mods, hmWin);

      fIsCapturing := False; // Stop capturing after one valid key
      if Assigned(fOnKeyCaptured) then fOnKeyCaptured(Self, Mods, VKey);
    end;
    Message.Result := 0;
    Exit;
  end;

  if Message.Msg = WM_HOTKEY then
  begin
    if fHotKeys.TryGetValue(Message.WParam, HotKeyRec) then
      if Assigned(fOnHotKey) then fOnHotKey(Self, HotKeyRec);
    Message.Result := 0;
  end
  else
    Message.Result := DefWindowProc(fHandle, Message.Msg, Message.WParam, Message.LParam);
end;

function THotKeyManager.Register(Modifiers: Word; VirtualKey: Word; RaiseOnError: Boolean): Integer;
var
  NewID: Integer;
  HotKeyRec: THotKeyRecord;
begin
  Result := 0;
  NewID := FNextHotKeyID;
  if Winapi.Windows.RegisterHotKey(fHandle, NewID, Modifiers, VirtualKey) then
  begin
    HotKeyRec.KeyID := NewID;
    HotKeyRec.VirtualKey := VirtualKey;
    HotKeyRec.Modifiers := Modifiers;
    fHotKeys.Add(NewID, HotKeyRec);
    Inc(fNextHotKeyID);
    Result := NewID;
  end
  else if RaiseOnError then
  begin
    if GetLastError = 1409 then
      raise EHotKeyError.Create('Collision: This hotkey is already claimed.')
    else
      raise EHotKeyError.Create('Windows Error ' + IntToStr(GetLastError));
  end;
end;

function THotKeyManager.Register(Modifiers: THKModifiers; VirtualKey: Word; RaiseOnError: Boolean): Integer;
var
  WinMods: Word;
begin
  WinMods := 0;
  if hmControl in Modifiers then WinMods := WinMods or MOD_CONTROL;
  if hmShift in Modifiers then WinMods := WinMods or MOD_SHIFT;
  if hmAlt in Modifiers then WinMods := WinMods or MOD_ALT;
  if hmWin in Modifiers then WinMods := WinMods or MOD_WIN;
  Result := Register(WinMods, VirtualKey, RaiseOnError);
end;

function THotKeyManager.Unregister(HotKeyID: Integer): Boolean;
begin
  Result := Winapi.Windows.UnregisterHotKey(fHandle, HotKeyID);
  if Result then fHotKeys.Remove(HotKeyID);
end;

procedure THotKeyManager.UnregisterAll;
var ID: Integer;
begin
  for ID in FHotKeys.Keys do Winapi.Windows.UnregisterHotKey(fHandle, ID);
  fHotKeys.Clear;
end;

end.