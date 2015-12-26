object OptionsForm: TOptionsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Options'
  ClientHeight = 153
  ClientWidth = 266
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 249
    Height = 137
    Caption = 'User Options'
    TabOrder = 0
    object Label1: TLabel
      Left = 24
      Top = 56
      Width = 150
      Height = 13
      Caption = 'Limit number of open copies to:'
    end
    object CheckBox1: TCheckBox
      Left = 24
      Top = 24
      Width = 193
      Height = 17
      Caption = 'Associate with .psv files'
      TabOrder = 0
    end
    object Button1: TButton
      Left = 24
      Top = 101
      Width = 75
      Height = 25
      Caption = 'Save'
      TabOrder = 1
    end
    object Button2: TButton
      Left = 142
      Top = 101
      Width = 75
      Height = 25
      Caption = 'Cancel'
      TabOrder = 2
    end
    object SpinEdit1: TSpinEdit
      Left = 181
      Top = 47
      Width = 37
      Height = 22
      MaxValue = 999
      MinValue = 1
      TabOrder = 3
      Value = 1
    end
  end
end
