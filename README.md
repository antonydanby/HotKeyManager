# Delphi Global HotKey Manager

A robust, non-visual component for Delphi that allows your application to respond to system-wide keyboard shortcuts. It features a modern non-visual architecture, "Key Capture" technology for easy shortcut assignment, and built-in collision detection to handle hotkey conflicts gracefully.

## 📁 Project Structure

* **`/`**: Contains the component source and implementation.
* **`Source/`**: Contains the `HotKeyManager.pas` unit.
* **`Demo/`**: A VCL application demonstrating registration, collision handling, and the "Key Capture" feature.

## 🚀 Features

* **Global Scope**: Recognizes keypresses even when your application is minimized or in the background.
* **Non-Visual Architecture**: Uses `AllocateHWnd` to manage Windows messages independently, removing the need for hidden forms.
* **Key Capture Mode**: Includes a "Capture" state that allows users to press a combination on their keyboard to automatically record and assign shortcuts.
* **Friendly Syntax**: Supports Delphi-style sets (e.g., `[hmControl, hmShift]`) instead of complex Windows API bitmasks.
* **Collision Detection**: Detects if another application (like Spotify or Discord) has already claimed a hotkey and provides clear error feedback.
* **Human-Readable Keys**: Built-in helper to convert virtual keys into friendly strings like "Ctrl+Alt+F12".

## 🛠 Installation

### Add to Project
1. Copy `HotKeyManager.pas` into your project source folder.
2. Add the unit to your project (`Project > Add to Project`).
3. Add `HotKeyManager` to the `uses` clause of your interface or implementation.

> This was developed in Rad Studio 13 (Athens), but it is compatible with any modern version of Delphi or Rad Studio (XE series through current), including the Community Edition.

## 📖 Usage Example

You can create the manager at runtime and assign an event handler to respond to the hotkey triggers.

### Registering a Hotkey
```pascal
procedure TMainForm.FormCreate(Sender: TObject);
begin
  FHotKeyManager := THotKeyManager.Create(Self);
  FHotKeyManager.OnHotKey := DoHotKeyNotify;
  
  // Register Ctrl + Shift + F12
  FHotKeyManager.Register([hmControl, hmShift], VK_F12, True);
end;

procedure TMainForm.DoHotKeyNotify(Sender: TObject; const HotKey: THotKeyRecord);
begin
  ShowMessage('Global Hotkey Pressed: ' + HotKey.ToKeyString);
end;
```

### Capturing a Hotkey from User Input

The **Key Capture** feature allows you to put the manager into a "listening" state. This is perfect for settings or configuration screens where you want the user to define their own shortcut by simply pressing it on their keyboard.

#### 1. Start the Capture
To begin listening for a key combination, call the `StartCapture` method. It is recommended to set focus to your form first to ensure it receives the initial key messages.

```pascal
procedure TMainForm.BtnAssignClick(Sender: TObject);
begin
  MemoLog.Lines.Add('>>> PRESS YOUR DESIRED HOTKEY COMBINATION NOW...');
  
  // Put the manager into listening mode
  FHotKeyManager.StartCapture;
  
  // Ensure the form has focus to intercept the messages
  Self.SetFocus; 
end;
```

#### 2. Handle the Captured Key

Once the user presses a valid combination (a modifier plus a primary key), the manager automatically stops capturing and fires the `OnKeyCaptured` event.

```pascal
procedure TMainForm.HotKeyManagerKeyCaptured(Sender: TObject; Modifiers: THKModifiers; VirtualKey: Word);
var
  TempRec: THotKeyRecord;
begin
  // Create a temporary record to utilize the ToKeyString helper
  TempRec.Modifiers := 0;
  if hmControl in Modifiers then TempRec.Modifiers := TempRec.Modifiers or MOD_CONTROL;
  if hmShift in Modifiers then TempRec.Modifiers := TempRec.Modifiers or MOD_SHIFT;
  if hmAlt in Modifiers then TempRec.Modifiers := TempRec.Modifiers or MOD_ALT;
  if hmWin in Modifiers then TempRec.Modifiers := TempRec.Modifiers or MOD_WIN;
  TempRec.VirtualKey := VirtualKey;

  MemoLog.Lines.Add('Captured User Input: ' + TempRec.ToKeyString);
  
  // Register the captured key as the new active global hotkey
  try
    // Unregister existing hotkey if necessary
    if FCurrentID <> 0 then 
      FHotKeyManager.Unregister(FCurrentID);
    
    // Register the new one with collision detection enabled (RaiseOnError = True)
    FCurrentID := FHotKeyManager.Register(Modifiers, VirtualKey, True);
    
    MemoLog.Lines.Add('SUCCESS: "' + TempRec.ToKeyString + '" is now active system-wide.');
  except
    on E: EHotKeyError do 
      ShowMessage('Could not assign this key: ' + E.Message);
  end;
end;
```

## Component Methods & Events

| Method/Event | Description |
| ----- | ----- |
| `Register(Modifiers, Key, RaiseOnError)` | Registers a global hotkey. Supports Delphi Sets or Windows Constants. |
| `Unregister(ID)` | Releases a specific hotkey by its unique ID. |
| `StartCapture` | Puts the manager into "listening" mode to record user input. |
| `OnHotKey` | Fires whenever a registered global shortcut is pressed. |
| `OnKeyCaptured` | Fires when a user provides input during Capture Mode. |

## Pros and Cons

### Pros
* **Clean Code**: No subclassing or manual `WndProc` overriding required in your main form.
* **UX Friendly**: The `ToKeyString` helper makes logging and UI displays effortless.
* **Robust**: Handles Windows Error 1409 (Hotkey Collision) specifically to prevent silent failures.

### Cons
* **Windows Only**: Relies on the Win32 `RegisterHotKey` API; not compatible with macOS or Linux.
* **Focus Required for Capture**: While hotkeys are global, the "Capture" mode requires your app to have focus to record the initial assignment.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

📩 Contact & Support

If you have questions, find a bug, or want to suggest a feature for the **Global HotKey Manager**, feel free to reach out:

* **Maintainer:** Antony Danby
* **GitHub:** [@AntonyDanby](https://github.com/antonydanby)  
* **Email:** [info@latitude53north.co.uk](mailto:info@latitude53north.co.uk)  
* **Website:** [latitude53north.co.uk](https://latitude53north.co.uk)

> [!TIP]
> If you encounter a collision where a hotkey cannot be registered, it is often because Windows "System" keys (like Win+L) or background apps (like Steam/Overlay software) have reserved that combination. Try a more unique combination like `Ctrl+Alt+Shift+[Key]`.
