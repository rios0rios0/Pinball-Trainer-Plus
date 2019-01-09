unit USpeedHack;

interface

uses Windows, Classes;

type
  TAPIInfo = record
    location: Pointer;
    Original: Array [0..4] of byte;
    Jump    : Array [0..4] of byte;
  end;

type
  TTick = class(TThread)
    private
    public
      procedure Execute; override;
    end;

procedure StopSpeedhack;
procedure InitializeSpeedhack;
procedure GetTime; stdcall; //function GetTime:dword; stdcall;
function NewQueryPerformanceCounter(var output: int64):BOOl; stdcall;

var
  CETick64: Int64;
  Ticker  : TTick;

  PerformanceFrequency, PerformanceFrequencyMS: Int64;
  Acceleration: Single;
  CETick, SleepTime: DWORD;
  Slow, TickerStopped, SpeedhackEnabled: Boolean;

  timeGetTimeInfo, getTickcountInfo, QueryPerformanceCounterInfo: TAPIInfo;
  winmmlib, kernel32lib: THandle;

implementation

procedure InitializeSpeedhack;
 var
  op: DWORD;
begin
  CETick := GetTickCount;
  {change the gettickcount and timegettime
  functions so that they look at cetick}
  if Ticker <> nil then
  begin
    Ticker.Terminate;
    StopSpeedhack;
  end;
  Ticker := nil;


  winmmlib := LoadLibrary('winmm.dll');
  if winmmlib <> 0 then
  begin
    timeGetTimeInfo.location:=GetProcAddress(winmmlib,'timeGetTime');
    if VirtualProtect(timeGetTimeInfo.location,5,PAGE_EXECUTE_READWRITE,op) then
    begin
      timeGetTimeInfo.jump[0]:=$e9;
      pdword(@timeGetTimeInfo.jump[1])^:=dword(@GetTime)-dword(timeGetTimeInfo.location)-5;

      try
        asm
          //store original
          push edi
          push esi
          lea edi,timeGetTimeInfo.original[0]
          mov esi,timeGetTimeInfo.location
          movsd
          movsb

          //replace with jump
          lea esi,timeGetTimeInfo.jump[0]
          mov edi,timeGetTimeInfo.location
          movsd
          movsb

          pop esi
          pop edi
        end;
      except

      end;
    end;
  end;


  kernel32lib := LoadLibrary('kernel32.dll');
  if kernel32lib <> 0 then
  begin
    //gettickcount
    GetTickCountInfo.location:=GetProcAddress(kernel32lib,'GetTickCount');
    if VirtualProtect(GetTickCountInfo.location,5,PAGE_EXECUTE_READWRITE,op) then
    begin
      GetTickCountInfo.jump[0]:=$e9;
      pdword(@GetTickCountInfo.jump[1])^:=dword(@GetTime)-dword(GetTickCountInfo.location)-5;

      try
        asm
          //store original
          push edi
          push esi
          lea edi,GetTickCountInfo.original[0]
          mov esi,GetTickCountInfo.location
          movsd
          movsb

          //replace with jump
          lea esi,GetTickCountInfo.jump[0]
          mov edi,GetTickCountInfo.location
          movsd
          movsb

          pop esi
          pop edi
        end;
      except

      end;
    end;


    //QueryPerformanceCounter
    if QueryPerformanceFrequency(PerformanceFrequency) then
    begin
      QueryPerformanceCounter(CETick64);
      PerformanceFrequencyMS:=PerformanceFrequency div 1000;

      //there is a high performance counter
      QueryPerformanceCounterInfo.location:=GetProcAddress(kernel32lib,'QueryPerformanceCounter');
      if VirtualProtect(QueryPerformanceCounterInfo.location,5,PAGE_EXECUTE_READWRITE,op) then
      begin
        QueryPerformanceCounterInfo.jump[0]:=$e9;
        pdword(@QueryPerformanceCounterInfo.jump[1])^:=dword(@NewQueryPerformanceCounter)-dword(QueryPerformanceCounterInfo.location)-5;

        try
          asm
            //store original
            push edi
            push esi
            lea edi,QueryPerformanceCounterInfo.original[0]
            mov esi,QueryPerformanceCounterInfo.location
            movsd
            movsb

            //replace with jump
            lea esi,QueryPerformanceCounterInfo.jump[0]
            mov edi,QueryPerformanceCounterInfo.location
            movsd
            movsb

            pop esi
            pop edi
          end;
        except

        end;
      end;
    end;
  end;

  SpeedhackEnabled := True;
  if Ticker = nil then
  Ticker := TTick.Create(False);
end;

procedure StopSpeedhack;
begin
  if not SpeedhackEnabled then
  Exit;
  SpeedhackEnabled := False;

  try
    asm
      lea esi,timeGetTimeInfo.original[0]
      mov edi,timeGetTimeInfo.location
      movsd
      movsb
    end;
  except

  end;

  try
    asm
      lea esi,GetTickCountInfo.original[0]
      mov edi,GetTickCountInfo.location
      movsd
      movsb
    end;
  except

  end;

  try
    asm
      lea esi,QueryPerformanceCounterInfo.original[0]
      mov edi,QueryPerformanceCounterInfo.location
      movsd
      movsb
    end;
  except

  end;

  FreeLibrary(winmmlib);
  FreeLibrary(kernel32lib);
  winmmlib := 0;
  kernel32lib := 0;
  if Ticker <> nil then Ticker.terminate;
  Ticker := nil;
end;


procedure GetTime; stdcall;
asm
  mov eax,[CETick]
  ret
end;

{function GetTime:dword; stdcall;
begin
  result:=CETick;
end;}

function NewQueryPerformanceCounter(var Output: Int64): BOOL; stdcall;
begin
  Output := CETick64;
  Result := True;
end;

procedure TTick.Execute;
begin
  TickerStopped := False;
  FreeOnTerminate := True;
  Priority := tpTimeCritical;
  //if not a thread with higher priority will prevent the timer from running
  while not Terminated do
  begin
    Inc(CETick64, Trunc(Acceleration * (PerformanceFrequency / (1000 / SleepTime))) );
    Inc(CETick, Trunc(SleepTime * Acceleration));
    Sleep(SleepTime);
  end;
  TickerStopped := True;
end;

initialization
  Acceleration := 1000;
  SleepTime := 3;
  InitializeSpeedhack;
end.
