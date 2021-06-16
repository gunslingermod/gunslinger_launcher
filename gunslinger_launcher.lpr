program gunslinger_launcher;

uses
  Interfaces,
  Forms,
  sysutils,
  IniFiles,
  windows,
  DateUtils,
  Localizer, ask_form;

type
ConfigurationParams = record
  time:TDateTime;
  configuration_valid:boolean;
  updates_present:boolean;
end;

const
  UPDATES_CHECK_PERIOD:integer = 1;

function ReadConfigurationParams():ConfigurationParams;
var
  ini:TIniFile;
  last_date:string;
const
  OPTIONS_CONFIG_NAME:string = 'update_configuration.ini';
  OPTIONS_SECT:string='main';
begin
  ini:=TIniFile.Create(OPTIONS_CONFIG_NAME);
  try
    result.configuration_valid:=strtointdef(ini.ReadString(OPTIONS_SECT, 'installation_valid', '1'), 1) > 0;
    result.updates_present:=strtointdef(ini.ReadString(OPTIONS_SECT, 'updates_present', '0'), 0) > 0;
    last_date:=ini.ReadString(OPTIONS_SECT, 'last_update_check', '');
    try
      result.time:=StrToDateTime(last_date);
    except
      result.time:=IncDay(Now(), -2 * UPDATES_CHECK_PERIOD);
    end;
  finally
    ini.Free;
  end;
end;

procedure KillerProc(hgame:HANDLE);
var
  kill_key_pressed:boolean;
  f4_state, ctrl_state:boolean;
begin
  kill_key_pressed:=false;
  while(WaitForSingleObject(hgame, 0) = WAIT_TIMEOUT) do begin
    f4_state:=GetAsyncKeyState(VK_F4) < 0;
    if f4_state then begin
      ctrl_state:=GetAsyncKeyState(VK_LCONTROL) < 0;
      if ctrl_state then begin
        if kill_key_pressed then begin
          TerminateProcess(hgame, 1013);
        end else begin
          kill_key_pressed:=true;
        end;
      end else begin
        kill_key_pressed:=false;
      end;
    end else begin
      kill_key_pressed:=false;
    end;

    Sleep(1000);
  end;
end;

procedure DoWork();
var
  cfg:ConfigurationParams;
  run_updater_string:string;
  run_mod_string:string;
  res:integer;
  decision:TUserDecision;

  game_handle:HANDLE;

  pi:TPROCESSINFORMATION;
  si:TSTARTUPINFO;
const
  UPDATER_EXECUTABLE_NAME:string = 'CheckUpdates.exe';
  MOD_EXECUTABLE_DIR:string='bin\';
  MOD_EXECUTABLE_NAME:string = 'xrEngine.exe';
  MOD_EXECUTABLE_PARAMS:string=' -no_staging';
  SILENT_KEY:string = 'silent';
  FAST_KEY:string = 'fast';
  INVALID_GAME_PID:cardinal=$FFFFFFFF;
begin
  run_updater_string:='';
  run_mod_string:='';

  cfg:=ReadConfigurationParams();
  if not cfg.configuration_valid then begin
    res:=Application.MessageBox(PAnsiChar(LocalizeString('err_inconsistent')), PAnsiChar(LocalizeString('err_caption')), MB_ICONERROR or MB_YESNO);
    if res = IDYES then begin
      run_updater_string:=UPDATER_EXECUTABLE_NAME+' '+FAST_KEY;
    end;
  end else if cfg.updates_present then begin;
    decision:=AskUpdateNow();
    if decision = RUN_UPDATE then begin
      run_updater_string:=UPDATER_EXECUTABLE_NAME+' '+FAST_KEY;
    end else if decision = RUN_GAME then begin
      run_mod_string:=MOD_EXECUTABLE_NAME;
    end;
  end else begin
    run_mod_string:=MOD_EXECUTABLE_NAME;
    if SecondsBetween(Now(), cfg.time) > SecsPerDay then begin
      run_updater_string:=UPDATER_EXECUTABLE_NAME+' '+SILENT_KEY;
    end;
  end;

  game_handle:=INVALID_HANDLE_VALUE;
  if length(run_mod_string)>0 then begin
    run_mod_string:=run_mod_string+MOD_EXECUTABLE_PARAMS;

    FillMemory(@si, sizeof(si),0);
    FillMemory(@pi, sizeof(pi),0);
    si.cb:=sizeof(si);
    CreateProcess(PAnsiChar(MOD_EXECUTABLE_DIR+MOD_EXECUTABLE_NAME), PAnsiChar(run_mod_string), nil, nil, false, 0, nil, nil, si, pi);
    game_handle:=pi.hProcess;
    CloseHandle(pi.hThread);
  end;

  if length(run_updater_string)>0 then begin
    FillMemory(@si, sizeof(si),0);
    FillMemory(@pi, sizeof(pi),0);
    si.cb:=sizeof(si);
    CreateProcess(PAnsiChar(UPDATER_EXECUTABLE_NAME), PAnsiChar(run_updater_string), nil, nil, false, 0, nil, nil, si, pi);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
  end;

  if game_handle<>INVALID_HANDLE_VALUE then begin
    KillerProc(game_handle);
    CloseHandle(game_handle);
  end;

end;

{$R *.res}

begin
  Application.Initialize;
  DoWork();
end.

