unit Localizer;

{$mode objfpc}{$H+}

interface

function LocalizeString(str:string):string;
function SelectLocalized(rus:string; eng:string):string;

implementation
uses windows;

function LocalizeString(str: string): string;
begin
  result:=str;
  if str = 'err_inconsistent' then begin
    result:=SelectLocalized('Файлы мода рассогласованы, запуск невозможен без обновления. Желаете запустить обновление сейчас?', 'Mod files in inconsistent state, update is required. Do you want to update now?');
  end else if str = 'info_updatefound' then begin
    result:=SelectLocalized('Доступно обновление. Желаете обновить мод сейчас?', 'New update found. Do you want to update the mod now?');
  end else if str = 'err_caption' then begin
    result:=SelectLocalized('Ошибка!', 'Error!');
  end else if str = 'info_caption' then begin
    result:=SelectLocalized('Информация', 'Information');
  end else if str = 'btn_yes_caption' then begin
    result:=SelectLocalized('Да', 'Yes');
  end else if str = 'btn_no_caption' then begin
    result:=SelectLocalized('Нет', 'No');
  end else if str = 'btn_info_caption' then begin
    result:=SelectLocalized('Подробнее...', 'Info');
  end else if str = 'btn_less_info_caption' then begin
    result:=SelectLocalized('Скрыть детали', 'Hide details');
  end else if str = 'btn_info_changelog' then begin
    result:=SelectLocalized('История версий', 'Change log');
  end else if str = 'components_to_update' then begin
    result:=SelectLocalized('Доступно обновление для следующих компонентов:', 'An update is available for the following components:');
  end;
end;

function SelectLocalized(rus: string; eng: string): string;
var
  locale:cardinal;
const
  RUS_ID:cardinal=1049;
begin
  locale:=GetSystemDefaultLangID();
  if locale = RUS_ID then begin
    result:=rus;
  end else begin
    result:=eng;
  end;
end;

end.

