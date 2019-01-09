library SpeedHack;

uses
  Windows;

var
  Speed32 : DWORD;
  Speed64, Frequency : Int64;
  Acceleration : Single = 2;
  SleepTime : DWORD = 5;

  timeGetTimeBytes : array [1..2] of DWORD;
  GetTickCountBytes : array [1..2] of DWORD;
  QueryPerformanceCounterBytes : array [1..2] of DWORD;
  x: Boolean = True;

{$R *.res}

function GetTime: DWORD; stdcall;
begin
  Result := Speed32;
end;

function NewQueryPerformanceCounter(var Output: Int64): BOOl; stdcall;
begin
  Output := Speed64;
  Result := True;
end;

procedure HookAndSaveBytes(Target, NewFunction : Pointer; var ByteToSave, DwordToSave : DWORD);
 var
  OldProtect : DWORD;
begin
  VirtualProtect(Target,5,PAGE_EXECUTE_READWRITE,@OldProtect);
  ByteToSave := Byte(PByte(Target)^);
  DwordToSave := Dword(PDword(Dword(Target)+1)^);
  PByte(Target)^ := $E9;
  PDword(Dword(Target)+1)^:= Dword(NewFunction)-Dword(Target)-5;
end;

procedure UnHook(Addr : Pointer; xByte, xDword : DWORD);
 var
  OldProtect : DWORD;
begin
  VirtualProtect(Addr,5,PAGE_EXECUTE_READWRITE,@OldProtect);
  PByte(Addr)^ := Byte(xByte);
  PDword(Dword(Addr)+1)^:= Dword(xDword);
end;

procedure UnHookSpeed;
begin
  x := False;
  UnHook(GetProcAddress(GetModuleHandle('winmm.dll'),'timeGetTime'),timeGetTimeBytes[1],timeGetTimeBytes[2]);
  UnHook(GetProcAddress(GetModuleHandle('kernel32.dll'),'GetTickCount'),GetTickCountBytes[1],GetTickCountBytes[2]);
  UnHook(GetProcAddress(GetModuleHandle('kernel32.dll'),'QueryPerformanceCounter'),QueryPerformanceCounterBytes[1],QueryPerformanceCounterBytes[2]);
end;

procedure Speed;
 var
  PHandle, Value, Buff: DWORD;
begin
  QueryPerformanceFrequency(Frequency);
  QueryPerformanceCounter(Speed64);
  while x do
  begin
    if (FindWindow('TFrmPTPPrincipal', nil) <> 0) then
    begin
      GetWindowThreadProcessId(FindWindow('TFrmPTPPrincipal', nil), PHandle);
      PHandle := OpenProcess(PROCESS_ALL_ACCESS, False, PHandle);
      ReadProcessMemory(PHandle, Pointer($004FB024), @Value, 4, Buff);
      Acceleration := Value;
      ReadProcessMemory(PHandle, Pointer($004FB020), @Value, 4, Buff);
      SleepTime := Value;
      ReadProcessMemory(PHandle, Pointer($004F97EC), @Value, 4, Buff);
      if (Value = 0) then
      begin
        UnHookSpeed;
        FreeLibraryAndExitThread(HInstance, 0);
      end;
      Inc(Speed64, Trunc(Acceleration * (Frequency / 200)));
      Inc(Speed32, Trunc(Acceleration * 5));
      Sleep(SleepTime);
    end else begin
      UnHookSpeed;
      FreeLibraryAndExitThread(HInstance, 0);
    end;
  end;
end;

procedure HookSpeed;
 var
  a : DWORD;
begin
  HookAndSaveBytes(GetProcAddress(GetModuleHandle('winmm.dll'),'timeGetTime'),@GetTime,timeGetTimeBytes[1],timeGetTimeBytes[2]);
  HookAndSaveBytes(GetProcAddress(GetModuleHandle('kernel32.dll'),'GetTickCount'),@GetTime,GetTickCountBytes[1],GetTickCountBytes[2]);
  HookAndSaveBytes(GetProcAddress(GetModuleHandle('kernel32.dll'),'QueryPerformanceCounter'),@NewQueryPerformanceCounter,QueryPerformanceCounterBytes[1],QueryPerformanceCounterBytes[2]);
  CreateThread(nil, 0, @Speed, nil, 0, a);
end;

procedure DllMain(Reason: DWORD);
 var
  a: DWORD;
begin
  if Reason = DLL_PROCESS_ATTACH then
  begin
    if (FindWindow('TFrmPTPPrincipal', nil) <> 0) then
    begin
      CreateThread(nil, 0, @HookSpeed, nil, 0, a);
    end else
      ExitProcess(0);
  end;
end;

begin
  DllProc := @DllMain;
  DllMain(DLL_PROCESS_ATTACH);
end.
