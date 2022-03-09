////////////////////////////////////////////
//                                        //
//        ћќƒ”Ћ№ ƒЋя “≈—“»–ќ¬јЌ»я         //
//                                        //
////////////////////////////////////////////

unit TestUnit;

interface

// иммитирует "создание сообщени€", на деле возвращает случайную строку длинной N (не больше N)
function CreateText(N: Integer = 15): String;

// иммитирует "создание статуса", на деле возвращает случайную строку из трех
function CreateStatus: String;

implementation

function CreateText(N: Integer = 15): String;
const
  symb = 'abcdefghijklmnopqrstuvwxyz0123456789';
var
  i: Integer;
begin
  //N := Random(N-1) + 1;
  Result := '';
  for i := 1 to N do begin
    Result := Result + symb[random(length(symb))+1]
  end;
end;

function CreateStatus: String;
const
  stat : array[0..2] of String = ('Critical', 'Warning', 'Info');
begin
  Result := stat[Random(High(stat)+1)];
end;

end.
