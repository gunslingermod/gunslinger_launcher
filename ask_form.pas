unit ask_form;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  TUserDecision = (RUN_UPDATE, RUN_GAME, DO_NOTHING);
  { TAskForm }

  TAskForm = class(TForm)
    btn_yes: TButton;
    btn_info: TButton;
    btn_changelog: TButton;
    lbl_update_msg: TLabel;
    btn_no: TToggleBox;
    memo_details: TMemo;
    procedure btn_changelogClick(Sender: TObject);
    procedure btn_infoClick(Sender: TObject);
    procedure btn_noChange(Sender: TObject);
    procedure btn_yesClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    _update_required:boolean;
    _show_changelist:boolean;
  public
    function GetUserUpdateDecision():TUserDecision;
    procedure FillDetails();
  end;

  function AskUpdateNow():TUserDecision;


implementation
uses Localizer, windows, IniFiles;

function AskUpdateNow(): TUserDecision;
var
  AskForm: TAskForm;
begin
  AskForm:=TAskForm.Create(nil);
  AskForm.ShowModal();
  result:=AskForm.GetUserUpdateDecision();
  AskForm.Free;
end;

{$R *.lfm}

{ TAskForm }

procedure TAskForm.FormCreate(Sender: TObject);
begin
  self.lbl_update_msg.Caption:=LocalizeString('info_updatefound');
  self.Caption:=LocalizeString('info_caption');
  self.btn_yes.Caption:=LocalizeString('btn_yes_caption');
  self.btn_no.Caption:=LocalizeString('btn_no_caption');
  self.btn_info.Caption:=LocalizeString('btn_info_caption');
  self.btn_changelog.Caption:=LocalizeString('btn_info_changelog');
  self.memo_details.Visible:=false;
  _update_required:=false;
  _show_changelist:=false;
  FillDetails();
end;

procedure TAskForm.btn_yesClick(Sender: TObject);
begin
  self._update_required:=true;
  self.Close();
end;

procedure TAskForm.btn_noChange(Sender: TObject);
begin
  self._update_required:=false;
  self.Close();
end;

procedure TAskForm.btn_changelogClick(Sender: TObject);
const
  url:PAnsiChar='https://github.com/gunslingermod/updater_links/blob/master/changes.list';
begin
  ShellExecute( Handle, 'open', url, nil, nil, SW_NORMAL );
  self._update_required:=false;
  self._show_changelist:=true;
  self.Close();
end;

procedure TAskForm.btn_infoClick(Sender: TObject);
begin
  if not self.memo_details.Visible then begin
    self.memo_details.Visible:=true;
    self.btn_info.Caption:=LocalizeString('btn_less_info_caption');
    self.lbl_update_msg.Visible:=false;
  end else begin
    self.memo_details.Visible:=false;
    self.btn_info.Caption:=LocalizeString('btn_info_caption');
    self.lbl_update_msg.Visible:=true;
  end;
end;

function TAskForm.GetUserUpdateDecision(): TUserDecision;
begin
    if _update_required then begin
      result:=RUN_UPDATE;
    end else if _show_changelist then begin
      result:=DO_NOTHING;
    end else begin
      result:=RUN_GAME;
    end;
end;

procedure TAskForm.FillDetails();
var
  ini:TIniFile;
  cnt, i:integer;
  str:string;
const
  OPTIONS_CONFIG_NAME:string = 'update_configuration.ini';
  OPTIONS_SECT:string='update_components';
begin
  ini:=TIniFile.Create(OPTIONS_CONFIG_NAME);
  try
    self.memo_details.Clear();
    self.memo_details.Lines.Add(LocalizeString('components_to_update'));
    cnt:=ini.ReadInteger(OPTIONS_SECT, 'lines_count', 0);
    for i:=0 to cnt-1 do begin
      str:=ini.ReadString(OPTIONS_SECT, 'line_'+inttostr(i), '');
      if length(str)>0 then begin
        self.memo_details.Lines.Add('- '+str);
      end;
    end;
  finally
    ini.Free;
  end;
end;

end.

