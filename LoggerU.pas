//////////////////////////////////////////////////////
//                                                  //
//                     ЛОГГЕР                       //
//                                                  //
//          Логгер ни чего ни о ком не знает        //
//            все им только пользуются              //
//      внешние силы присваивают значения его       //
//          полям и вызывают его методы             //
//                                                  //
//         паттерне MVC это фрагмент Model          //
//                                                  //
//////////////////////////////////////////////////////

unit LoggerU;

interface

uses
  Windows, syncobjs, classes;

const
  cSeparator = '    ' + #$9;          // разделитель, разделяющий сообщение, статус идентификатор потока и время
  cDTFormat  = 'dd.mm.yyyy hh:mm:ss'; // формат даты-времени для записи в лог-файл (чтобы была фиксированная длинна)
  cMessageListCapacity = 10;          // столько последних сообщений Логгер должен держать в памяти

type
// для процедуры, которая передает сообщения, хранящиеся в памяти, в интерфейс, если таковой будет
TRefreshGraficInterface = procedure(s: String);

TLogger = class
private
  MessageList: TStringList;           // память для последних 10 сообщений
  CSM        : TCriticalSection;      // критическая секция для защиты доступа к памяти
  CSF        : TCriticalSection;      // критическая секция для защиты доступа к лог-файлу
  CSI        : TCriticalSection;      // критическая секция для защиты обновления интерфейса
  // тут, на прошлом заходе, я дейстительно, жидко обосрался... "кишки наружу" - это точно
public
  LogFileName:   String;              // имя лог-файла
  OnRefreshGraficInterface: TRefreshGraficInterface; // если будет какой-то интерфейс, то он присвоит сюда свою процедуру
  constructor Create(logfile_name: String);
  destructor Destroy; override;
  procedure Write(TextMessage: String; StatusMessage: String); // запись в лог-файл;
  procedure Clear;                    // очистка файла;
end;

var
  Logger:  TLogger;                   // Логгер - главный объект задния № 1

implementation

uses
  sysutils, DateUtils, Consta;

{ TLogger }

procedure TLogger.Clear;
// логика очистки следующая:
// сообщения в лог-файле однозначно отсортированы сверху вниз по возрастанию момента создания
// значит нужно оставить ту часть лог-файла, которая ниже последней записи
// время создания, которой отстоит от текущего момента на заданное кол-во минут
// таким образом мы пропустим все записи до нужной, скопируем оставшуюся часть лог-файла
// во временный файл, удалим лог-файл, и переименуем временный файл в лог-файл
const
  TmpFileName = 'i9psoafar21vbqzqya0.txt';  // имя для временного файла
var
  o, n: TextFile;
  s, d: String;
  b: Boolean;
  dt, nd: TDateTime;
  mb: Int64;
begin
  AssignFile(o, LogFileName);                 // связываемся с лог-файлом
  if not FileExists(LogFileName) then exit;   // если лог-файла нет, то и делать нечего - выходим
  // иначе остаемся и работаем
  AssignFile(n, TmpFileName);                 // связываемся с временным файлом
  CSF.Enter;                                  // запрещаем доступ к лог-файлу для всех остальных
  try
    Reset(o);                                 // открываем лог-файл на чтение
    Rewrite(n);                               // пересоздаем временный файл на запись
    b := true; // пока b установлена в true мы будем смотреть на момент создания записи и не будем забирать эту запись в очищеный лог-файл, потому что запись старая
    nd := Now();                              // запоминаем текущий момент
    try
      while not Eof(o) do begin               // побежали по лог-файлу
        Readln(o, s);                         // считали запись
        if b then begin                       // если предполагаем, что считанная запись старая
          // то проверим действительно ли она старая?
          // момент создания записи записан в формате cDTFormat в конце строки, поэтому легко извлекаем
          d := Copy(s, Length(s) - Length(cDTFormat) + 1, Length(cDTFormat));
          dt := StrToDateTime(d);             // преобразуем
          mb := MinutesBetween(nd, dt);       // берем разницу между моментом создания и текущим в минутах
          b := mb >= cTimeMessage;            // как только появиться не старая запись b установиться в false
          // и с этого момента мы знаем, что ниже старых записей нет и проверок момента создания больше делать не будем
        end;
        if not b then Writeln(n, s);          // если запись не старая, то пишем во временнй файл
      end;
    finally
      CloseFile(o);
      CloseFile(n);
    end;
    // Если программа запущена с параметром t, то для удобства контроля правильности функционирования
    // очищаемый лог сохраняется в состоянии "до" (_bef_) и "после" (_aft_);
    if ParamStr(1) = 't' then begin
      CopyFile(PWideChar(LogFileName), PWideChar(FormatDateTime('hh_mm_ss', nd) + '_bef_' + LogFileName), false);
      CopyFile(PWideChar(TmpFileName), PWideChar(FormatDateTime('hh_mm_ss', nd) + '_aft_' + LogFileName), false);
    end;
    DeleteFile(LogFileName);                  // удаляем старый лог-файл
    RenameFile(TmpFileName, LogFileName);     // временный файл переименовываем в лог-файл
  finally
    CSF.Leave;                                // открываем доступ к лог-файлу
  end;
end;

constructor TLogger.Create(logfile_name: String);
begin
  MessageList := TStringList.Create;
  MessageList.Capacity := cMessageListCapacity;
  LogFileName := logfile_name;
  CSM := TCriticalSection.Create;
  CSF := TCriticalSection.Create;
  CSI := TCriticalSection.Create;
end;

destructor TLogger.Destroy;
begin
  CSI.Free;
  CSF.Free;
  CSM.Free;
  MessageList.Free;
  inherited;
end;

procedure TLogger.Write(TextMessage: String; StatusMessage: String);
var
  s: String;
  f: TextFile;
begin
  CSM.Enter;                                         // закрываем доступ к памяти
  try                                                // работаем с памятью
    if MessageList.Count = cMessageListCapacity then // если сообщений в памяти уже предел, то
      MessageList.Delete(cMessageListCapacity - 1);  // удаляем самое старое, то есть последнее
    MessageList.Insert(0, TextMessage);              // новое вставляем в начало
  finally                                            // не смотря ни на какие неприятности
    CSM.Leave;                                       // открываем доступ к памяти
  end;
  s := TextMessage + cSeparator + StatusMessage + cSeparator + IntToStr(GetCurrentThreadId)
    + cSeparator + FormatDateTime(cDTFormat, Now()); // собирам строку, которую добавим в лог-файл
  CSF.Enter;                                         // закрываем доступ к лог-файлу
  try
    AssignFile(f, LogFileName);                      // связываемся с лог-файлом
    if FileExists(LogFileName)                       // если лог-файл имеется
      then Append(f)                                 // то открываем его на добавление
      else Rewrite(f);                               // иначе создаем и открываем на запись
    try                                              // пытаемся
      Writeln(f, s);                                 // добавить строку в лог-файл
    finally                                          // не смотря ни на какие неприятности
      CloseFile(f);                                  // закрываем лог-файл
    end;
  finally                                            // не смотря ни на какие неприятности
    CSF.Leave;                                       // открываем доступ к лог-файлу
  end;
  CSI.Enter;                                         // закрываем доступ к обновлению интерфейса
  try
    if Assigned(OnRefreshGraficInterface) then       // если какому-то интерфейсу нужно
      OnRefreshGraficInterface(MessageList.Text);    // то посылаем ему данные для отображения
  finally                                            // не смотря ни на какие неприятности
    CSI.Leave;                                       // открываем доступ к обновлению интерфейса
  end;
end;

end.
