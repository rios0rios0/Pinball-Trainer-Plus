unit UPTP;

interface

uses
  Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  ExtCtrls, ComCtrls, Buttons, Menus, XPMan, sSkinManager, sLabel, sTrackBar,
  sCheckBox, sSpeedButton, sBitBtn, sEdit, sGroupBox, ShellApi, Tlhelp32;

type
  TFrmPTPPrincipal = class(TForm)
    TmrFreezePontos: TTimer;
    TmrFreezeBolas: TTimer;
    TmrAtualiza: TTimer;
    Mm: TMainMenu;
    MniMais: TMenuItem;
    MniInstall: TMenuItem;
    MniSobre: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    MniAparencia: TMenuItem;
    MniSkin: TMenuItem;
    sSknmngr: TsSkinManager;
    sEdtBolas: TsEdit;
    sBtbtnBolas: TsBitBtn;
    sEdtPontos: TsEdit;
    sBtbtnPontos: TsBitBtn;
    LblVerifica: TLabel;
    LblBolas: TLabel;
    LblPontos: TLabel;
    LblPid: TLabel;
    LblCheats: TLabel;
    LblPrimar: TLabel;
    sTrckbr1: TsTrackBar;
    sTrckbr2: TsTrackBar;
    sChkFreezeBolas: TsCheckBox;
    sChkFreezePontos: TsCheckBox;
    sChkSpeedHack: TsCheckBox;
    sTrckbrSpeed: TsTrackBar;
    LblVelocidade: TLabel;
    sTrckbrSleep: TsTrackBar;
    LblIntervalo: TLabel;
    sEdtSpeed: TsEdit;
    sBtbtnSetar: TsBitBtn;
    sChkCheats: TsCheckBox;
    Xpmnfst: TXPManifest;
    sChkMortes: TsCheckBox;
    procedure sBtbtnBolasClick(Sender: TObject);
    procedure sBtbtnPontosClick(Sender: TObject);
    procedure TmrFreezePontosTimer(Sender: TObject);
    procedure TmrFreezeBolasTimer(Sender: TObject);
    procedure TmrAtualizaTimer(Sender: TObject);
    procedure MniSobreClick(Sender: TObject);
    procedure MniInstallClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sEdtBolasKeyPress(Sender: TObject; var Key: Char);
    procedure MniSkinClick(Sender: TObject);
    procedure sTrckbr1Change(Sender: TObject);
    procedure sTrckbr2Change(Sender: TObject);
    procedure sChkFreezeBolasClick(Sender: TObject);
    procedure sChkFreezePontosClick(Sender: TObject);
    procedure sTrckbrSpeedChange(Sender: TObject);
    procedure sChkSpeedHackClick(Sender: TObject);
    procedure sTrckbrSleepChange(Sender: TObject);
    procedure sBtbtnSetarClick(Sender: TObject);
    procedure sChkCheatsClick(Sender: TObject);
    procedure sChkMortesClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmPTPPrincipal : TFrmPTPPrincipal;
  SpeedHackSleep  : DWORD;
  SpeedHackSpeed  : DWORD;
  SpeedHackActiv  : DWORD = 0;
  PHandle         : THandle;

const
  //Pontos
  ADDRESS_SCORE  : DWORD = $01025040;
  OFFSET_SCORE   : DWORD = $52;
  //Bolas
  ADDRESS_BALL   : DWORD = $01025040;
  OFFSET_BALL    : DWORD = $146;
  //Cheats
  ADDRESS_CHEATS : DWORD = $01024FF8;
  ADDRESS_DEATHS : DWORD = $01025044;
  //Batedores Primários
  ADDRESS_BAT1_1 : DWORD = $010236E4;
  OFFSET_BAT1_1  : DWORD = $4E;
  ADDRESS_BAT1_2 : DWORD = $010236F4;
  OFFSET_BAT1_2  : DWORD = $4E;
  ADDRESS_BAT1_3 : DWORD = $010236EC;
  OFFSET_BAT1_3  : DWORD = $4E;
  ADDRESS_BAT1_4 : DWORD = $010236FC;
  OFFSET_BAT1_4  : DWORD = $4E;
  //Batedores Secundários
  ADDRESS_BAT2_1 : DWORD = $01023768;
  OFFSET_BAT2_1  : DWORD = $4E;
  ADDRESS_Bat2_2 : DWORD = $01023758;
  OFFSET_BAT2_2  : DWORD = $4E;
  ADDRESS_BAT2_3 : DWORD = $01023760;
  OFFSET_BAT2_3  : DWORD = $4E;

implementation

{$R *.dfm}
{$R Resources\SpeedHack.res}
{$R Resources\Installer.res}

function GetProcessIDbyName(ProcessName: string): DWORD;
 var
  MyHandle: THandle;
  Struct: TProcessEntry32;
begin
  Result := 0;
  ProcessName := LowerCase(ProcessName);
  try
    MyHandle := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);
    Struct.dwSize := Sizeof(TProcessEntry32);
    if Process32First(MyHandle, Struct) then
    if ProcessName = LowerCase(Struct.szExeFile) then
    begin
      Result := Struct.th32ProcessID;
      Exit;
    end;
    while Process32Next(MyHandle, Struct) do
    if ProcessName = LowerCase(Struct.szExeFile) then
    begin
      Result := Struct.th32ProcessID;
      Exit;
    end;
  except
    Exit;
  end;
end;

function InjectDll(hOpen: THandle; sDll: string): Boolean;
 var
  hLib, pMod: Pointer;
  hThread: THandle;
  dWritten, ThreadID: Cardinal;
begin
  Result := False;
  if hOpen <> INVALID_HANDLE_VALUE then
  begin
    hLib := GetProcAddress(GetModuleHandle(PChar('kernel32.dll')), PChar('LoadLibraryA'));
    pMod := VirtualAllocEx(hOpen, nil, Length(sDll) + 1, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if WriteProcessMemory(hOpen, pMod, @sDll[1], Length(sDll), dWritten) then
    Result := True;
    hThread := CreateRemoteThread(hOpen, nil, 0, hLib, pMod, 0, ThreadID);
    WaitForSingleObject(hThread, INFINITE);
    CloseHandle(hOpen);
    CloseHandle(hThread);
  end;
end;

function WriteMemoryBytes(Address, Offset, NewValue: DWORD): Boolean;
 var
  Value, Buff: DWORD;
begin
  try
    ReadProcessMemory(PHandle, Pointer(Address), @Value, 4, Buff);
    Value := Value + Offset;
    WriteProcessMemory(PHandle, Pointer(Value), @NewValue, 4, Buff);
    Result := True;
  except
    Result := False;
  end;
end;

function CreateResource(FileName: string; Resource, Typ: PChar): Boolean;
 var
  Res : TResourceStream;
begin
  Result := False;
  Res := TResourceStream.Create(HInstance, Resource, Typ);
  try
    Res.SaveToFile(FileName);
  except
    Result := False;
    Res.Free;
  end;
  Res.Free;
  Result := True;
end;

procedure AjustmentComponents(Status: Boolean);
begin
  FrmPTPPrincipal.sTrckbr1.Enabled := Status;
  FrmPTPPrincipal.sTrckbr2.Enabled := Status;
  FrmPTPPrincipal.sChkSpeedHack.Enabled := Status;
  FrmPTPPrincipal.sChkCheats.Enabled := Status;
  FrmPTPPrincipal.sChkMortes.Enabled := Status;
  FrmPTPPrincipal.sEdtPontos.Enabled := Status;
  FrmPTPPrincipal.sEdtBolas.Enabled := Status;
  FrmPTPPrincipal.sBtbtnPontos.Enabled := Status;
  FrmPTPPrincipal.sBtbtnBolas.Enabled := Status;
end;

procedure TFrmPTPPrincipal.sBtbtnBolasClick(Sender: TObject);
begin
  if sEdtBolas.Text <> '' then
  begin
    sChkfreezebolas.Enabled := True;
    WriteMemoryBytes(ADDRESS_BALL, OFFSET_BALL, StrToInt(sEdtBolas.Text));
  end;
end;

procedure TFrmPTPPrincipal.sBtbtnPontosClick(Sender: TObject);
begin
  if sEdtPontos.Text <> '' then
  begin
    sChkFreezePontos.Enabled := True;
    WriteMemoryBytes(ADDRESS_SCORE, OFFSET_SCORE, StrToInt(sEdtPontos.Text));
  end;
end;

procedure TFrmPTPPrincipal.TmrFreezePontosTimer(Sender: TObject);
begin
  sBtbtnPontos.Click;
end;

procedure TFrmPTPPrincipal.TmrFreezeBolasTimer(Sender: TObject);
begin
  sBtbtnBolas.Click;
end;

procedure TFrmPTPPrincipal.TmrAtualizaTimer(Sender: TObject);
 var
  Value, Buff: DWORD;
begin
  if (FindWindow('1c7c22a0-9576-11ce-bf80-444553540000', nil) <= 0) then
  begin
    LblVerifica.Caption:= ('PinBall Não Identificado...');
    LblVerifica.Font.Color := clRed;
    LblPontos.Caption := 'Pontos: ???';
    LblBolas.Caption := 'Bolas: ???';
    LblPid.Caption := 'PID: ???';
    AjustmentComponents(False);
    sEdtPontos.Text := '';
    sEdtBolas.Text := '';
    sEdtSpeed.Text := '0';
    sEdtSpeed.Enabled := False;
    sTrckbr1.Position := 0;
    sTrckbr2.Position := 0;
    sTrckbrSpeed.Position := 0;
    sTrckbrSleep.Position := 0;
    sTrckbrSpeed.Enabled := False;
    sTrckbrSleep.Enabled := False;
    sChkFreezePontos.Enabled := False;
    sChkFreezePontos.Checked := False;
    sChkFreezeBolas.Enabled := False;
    sChkFreezeBolas.Checked := False;
    sChkSpeedHack.Checked := False;
    sChkCheats.Checked := False;
    sChkMortes.Checked := False;
    sBtbtnSetar.Enabled := False;
  end else begin
    PHandle := OpenProcess(PROCESS_ALL_ACCESS, FALSE, GetProcessIDbyName('pinball.exe'));
    LblPid.Caption := 'PID: ' + IntToStr(GetProcessIDbyName('pinball.exe'));
    LblVerifica.Caption := 'PinBall Identificado,  Aguardando...';
    LblVerifica.Font.Color := clGreen;
    AjustmentComponents(True);
    //Ler Pontos
    ReadProcessMemory(PHandle, Pointer(Address_Score), @Value, 4, Buff);
    Value := Value + OFFSET_SCORE;
    ReadProcessMemory(PHandle, Pointer(Value), @Value, 4, Buff);
    LblPontos.Caption := ('Pontos: ' + IntToStr(Value));
    //Ler Bolas
    ReadProcessMemory(PHandle, Pointer(Address_Ball), @Value, 4, Buff);
    Value := Value + Offset_Ball;
    ReadProcessMemory(PHandle, Pointer(Value), @Value, 4, Buff);
    LblBolas.Caption := ('Bolas: '+IntToStr(Value));
    //Ler Cheats
    ReadProcessMemory(PHandle, Pointer(ADDRESS_CHEATS), @Value, 4, Buff);
    sChkCheats.Checked := Boolean(Value);
    //Ler Mortes
    ReadProcessMemory(PHandle, Pointer(ADDRESS_DEATHS), @Value, 4, Buff);
    sChkMortes.Checked := Boolean(Value);
    //Ler Batedores Primários
    ReadProcessMemory(PHandle, Pointer(ADDRESS_BAT1_1), @Value, 4, Buff);
    Value := Value + OFFSET_BAT1_1;
    ReadProcessMemory(PHandle, Pointer(Value), @Value, 4, Buff);
    sTrckbr1.Position := Value;
    //Ler Batedores Secundários
    ReadProcessMemory(PHandle, Pointer(ADDRESS_BAT2_1), @Value, 4, Buff);
    Value := Value + OFFSET_BAT2_1;
    ReadProcessMemory(PHandle, Pointer(Value), @Value, 4, Buff);
    sTrckbr2.Position := Value;
  end;
end;

procedure TFrmPTPPrincipal.MniSobreClick(Sender: TObject);
begin
  MessageBox(Handle, 'Pinball Trainer Plus v1.0' + #13 + #13
  + 'Criado Por rios0rios0' + #13 + #13 + 'Contato: rios0rios0@outlook.com',
  'Info (Sobre)', MB_OK + MB_DEFBUTTON1 + MB_ICONINFORMATION);
end;

procedure TFrmPTPPrincipal.MniInstallClick(Sender: TObject);
 var
  FileName : string;
begin
  FileName := GetCurrentDir + '\Pinball Installer.exe';
  if MessageBox(
  Handle, 'Deseja Instalar o 3D Pinball for Windows - Space Cadet?',
  'Confirmação', MB_YESNO + MB_DEFBUTTON1 + MB_ICONQUESTION) = IDYES then
  begin
    if not FileExists(FileName) then
    begin
      if CreateResource(FileName, 'PINBALLINSTALLER', 'EXE') then
      ShellExecute(Handle, 'open', PChar(FileName), '', '', SW_SHOWNORMAL)
      else
      MessageBox(
      Handle, 'Ocorreu Um Erro na Criação do Recurso!',
      'Erro', MB_OK + MB_DEFBUTTON1 + MB_ICONWARNING);
    end else begin
      ShellExecute(Handle, 'open', PChar(FileName), '', '', SW_SHOWNORMAL);
    end;
  end else begin
    Exit;
  end;
end;

procedure TFrmPTPPrincipal.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if FileExists(GetCurrentDir + '\SpeedHack.dll') then
  begin
    DeleteFile(GetCurrentDir + '\SpeedHack.dll');
  end;
  if FileExists(GetCurrentDir + '\Pinball Installer.exe') then
  begin
    DeleteFile(GetCurrentDir + '\Pinball Installer.exe');
  end;
  AnimateWindow(Handle, 1000, AW_HIDE + AW_BLEND);
end;

procedure TFrmPTPPrincipal.sEdtBolasKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in [#48..#57]) or (Key in [#8])) then
  begin
    Key := #0;
  end;
end;

procedure TFrmPTPPrincipal.MniSkinClick(Sender: TObject);
begin
  sSknmngr.Active := MniSkin.Checked;
end;

procedure TFrmPTPPrincipal.sTrckbr1Change(Sender: TObject);
begin
  WriteMemoryBytes(ADDRESS_BAT1_1, OFFSET_BAT1_1, sTrckbr1.Position);
  WriteMemoryBytes(ADDRESS_BAT1_2, OFFSET_BAT1_2, sTrckbr1.Position);
  WriteMemoryBytes(ADDRESS_BAT1_3, OFFSET_BAT1_3, sTrckbr1.Position);
  WriteMemoryBytes(ADDRESS_BAT1_4, OFFSET_BAT1_4, sTrckbr1.Position);
end;

procedure TFrmPTPPrincipal.sTrckbr2Change(Sender: TObject);
begin
  WriteMemoryBytes(ADDRESS_BAT2_1, OFFSET_BAT2_1, sTrckbr2.Position);
  WriteMemoryBytes(ADDRESS_BAT2_2, OFFSET_BAT2_2, sTrckbr2.Position);
  WriteMemoryBytes(ADDRESS_BAT2_3, OFFSET_BAT2_3, sTrckbr2.Position);
end;

procedure TFrmPTPPrincipal.sChkCheatsClick(Sender: TObject);
 var
  Value, Buff: DWORD;
begin
  Value := Integer(sChkCheats.Checked);
  WriteProcessMemory(PHandle, Pointer(ADDRESS_CHEATS), @Value, 4, Buff);
end;

procedure TFrmPTPPrincipal.sChkMortesClick(Sender: TObject);
 var
  Value, Buff: DWORD;
begin
  Value := Integer(sChkMortes.Checked);
  WriteProcessMemory(PHandle, Pointer(ADDRESS_DEATHS), @Value, 4, Buff);
end;

procedure TFrmPTPPrincipal.sChkFreezeBolasClick(Sender: TObject);
begin
  tmrfreezebolas.Enabled := sChkFreezeBolas.Checked;
  sBtbtnBolas.Visible := (not sChkFreezeBolas.Checked);
  sEdtBolas.Visible := (not sChkFreezeBolas.Checked);
  sBtbtnBolas.Click;
end;

procedure TFrmPTPPrincipal.sChkFreezePontosClick(Sender: TObject);
begin
  tmrfreezepontos.Enabled := sChkFreezePontos.Checked;
  sBtbtnPontos.Visible := (not sChkFreezePontos.Checked);
  sEdtPontos.Visible := (not sChkFreezePontos.Checked);
  sBtbtnPontos.Click;
end;

procedure TFrmPTPPrincipal.sTrckbrSleepChange(Sender: TObject);
begin
  SpeedHackSleep := sTrckbrSleep.Position;
end;

procedure TFrmPTPPrincipal.sTrckbrSpeedChange(Sender: TObject);
begin
  case sTrckbrSpeed.Position of
    0..2: SpeedHackSpeed := sTrckbrSpeed.Position * 2;
    3..4: SpeedHackSpeed := sTrckbrSpeed.Position * 5;
    5..6: SpeedHackSpeed := sTrckbrSpeed.Position * 10;
    7..9: SpeedHackSpeed := sTrckbrSpeed.Position * 50;
      10: SpeedHackSpeed := sTrckbrSpeed.Position * 100;
  end;
  sEdtSpeed.Text := IntToStr(SpeedHackSpeed);
end;

procedure TFrmPTPPrincipal.sChkSpeedHackClick(Sender: TObject);
begin
  sTrckbrSpeed.Enabled := sChkSpeedHack.Checked;
  sTrckbrSleep.Enabled := sChkSpeedHack.Checked;
  sBtbtnSetar.Enabled := sChkSpeedHack.Checked;
  sEdtSpeed.Enabled := sChkSpeedHack.Checked;
  SpeedHackActiv := Integer(sChkSpeedHack.Checked);
  sEdtSpeed.Text := '0';
  sTrckbrSpeed.Position := 0;
  sTrckbrSleep.Position := 0;
  SpeedHackSpeed := sTrckbrSpeed.Position;
  SpeedHackSleep := sTrckbrSleep.Position;
end;

procedure TFrmPTPPrincipal.sBtbtnSetarClick(Sender: TObject);
 var
  FileName : string;
begin
  FileName := GetCurrentDir + '\SpeedHack.dll';
  if not FileExists(FileName) then
  begin
    if CreateResource(FileName, 'SPEEDHACK', 'DLL') then
    begin
      if not InjectDll(PHandle, GetCurrentDir + '\SpeedHack.dll') then
      begin
        MessageBox(
        Handle, 'Ocorreu Um Erro na Ativação do Recurso!',
        'Erro', MB_OK + MB_DEFBUTTON1 + MB_ICONWARNING);
      end;
    end else
      MessageBox(
      Handle, 'Ocorreu Um Erro na Criação do Recurso!',
      'Erro', MB_OK + MB_DEFBUTTON1 + MB_ICONWARNING);
  end else
    if not InjectDll(PHandle, GetCurrentDir + '\SpeedHack.dll') then
    begin
      MessageBox(
      Handle, 'Ocorreu Um Erro na Ativação do Recurso!',
      'Erro', MB_OK + MB_DEFBUTTON1 + MB_ICONWARNING);
    end;
end;

end.
