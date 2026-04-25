object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderWidth = 4
  Caption = 'HotKey Picker Demo'
  ClientHeight = 370
  ClientWidth = 466
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  DesignSize = (
    466
    370)
  TextHeight = 15
  object MemoLog: TMemo
    Left = 0
    Top = 0
    Width = 466
    Height = 313
    Align = alTop
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
    ExplicitWidth = 442
    ExplicitHeight = 273
  end
  object ButtonRegister: TButton
    Left = 8
    Top = 332
    Width = 140
    Height = 30
    Anchors = [akLeft, akBottom]
    Caption = 'Test Hardcoded (F8)'
    TabOrder = 1
    OnClick = ButtonRegisterClick
    ExplicitTop = 302
  end
  object ButtonAssign: TButton
    Left = 156
    Top = 332
    Width = 140
    Height = 30
    Anchors = [akLeft, akBottom]
    Caption = 'Assign New Hotkey'
    TabOrder = 2
    OnClick = ButtonAssignClick
    ExplicitTop = 302
  end
  object ButtonUnregister: TButton
    Left = 318
    Top = 332
    Width = 140
    Height = 30
    Anchors = [akRight, akBottom]
    Caption = 'Clear All'
    Enabled = False
    TabOrder = 3
    OnClick = ButtonUnregisterClick
    ExplicitLeft = 302
    ExplicitTop = 302
  end
  object HotKeyManager: THotKeyManager
    OnHotKey = HotKeyManagerNotify
    OnKeyCaptured = HotKeyManagerKeyCaptured
    Left = 48
    Top = 24
  end
end
