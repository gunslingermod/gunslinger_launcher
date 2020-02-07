program gunslinger_launcher;

uses
  Interfaces,
  Forms,
  sysutils,
  IniFiles,
  windows,
  DateUtils,
  Localizer;

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

procedure DoWork();
var
  cfg:ConfigurationParams;
  run_updater_string:string;
  run_mod_string:string;
  res:integer;

  pi:TPROCESSINFORMATION;
  si:TSTARTUPINFO;
const
  UPDATER_EXECUTABLE_NAME:string = 'CheckUpdates.exe';
  MOD_EXECUTABLE_DIR:string='bin\';
  MOD_EXECUTABLE_NAME:string = 'xrEngine.exe';
  SILENT_KEY:string = 'silent';
begin
  run_updater_string:='';
  run_mod_string:='';

  cfg:=ReadConfigurationParams();
  if not cfg.configuration_valid then begin
    res:=Application.MessageBox(PAnsiChar(LocalizeString('err_inconsistent')), PAnsiChar(LocalizeString('err_caption')), MB_ICONERROR or MB_YESNO);
    if res = IDYES then begin
      run_updater_string:=UPDATER_EXECUTABLE_NAME;
    end;
  end else if cfg.updates_present then begin;
    res:=Application.MessageBox(PAnsiChar(LocalizeString('info_updatefound')), PAnsiChar(LocalizeString('info_caption')), MB_ICONINFORMATION or MB_YESNO);
    if res = IDYES then begin
      run_updater_string:=UPDATER_EXECUTABLE_NAME;
    end else begin
      run_mod_string:=MOD_EXECUTABLE_NAME;
    end;
  end else begin
    run_mod_string:=MOD_EXECUTABLE_NAME;
    if SecondsBetween(Now(), cfg.time) > SecsPerDay then begin
      run_updater_string:=UPDATER_EXECUTABLE_NAME+' '+SILENT_KEY;
    end;
  end;

  if length(run_mod_string)>0 then begin
    FillMemory(@si, sizeof(si),0);
    FillMemory(@pi, sizeof(pi),0);
    si.cb:=sizeof(si);
    CreateProcess(PAnsiChar(MOD_EXECUTABLE_DIR+MOD_EXECUTABLE_NAME), PAnsiChar(run_mod_string), nil, nil, false, 0, nil, nil, si, pi);
    CloseHandle(pi.hProcess);
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

end;

{$R *.res}

begin
  Application.Initialize;
  DoWork();
end.

