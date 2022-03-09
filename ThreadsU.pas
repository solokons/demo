////////////////////////////////////////////////////////
//                                                    //
//                       ѕќ“ќ »                       //
//                                                    //
// в задании сказано "реализовать удаление старых..." //
// ограничений не наложено, поэтому выбор реализации  //
// делаем самосто€тельно, значит это тоже будет поток //
//                                                    //
// потоки знают только о Ћоггере                      //
// периодически командуют ему                         //
// потоки-писатели: записать сообщение, статус        //
// поток-чистильщик: почистить файл                   //
//                                                    //
//        в паттерне MVC это фрагмент Model           //
//                                                    //
////////////////////////////////////////////////////////

unit ThreadsU;

interface

uses
  Classes;

type
  // поток-писатель, генирирует сообщение и статус, и периодически командует Ћоггеру их записать
  TMyWriter = class(TThread)
  protected
    procedure Execute; override;
  public
    PeriodWrite: Cardinal; // период создани€ сообщени€ в миллисекундах
  end;

  // поток-чистильщик, периодически командует Ћоггеру удалить устаревшие записи
  TMyCleaner = class(TThread)
  protected
    procedure Execute; override;
  public
    TimeClear: Cardinal; // период очистки лог-файла от устаревших сообщений в миллисекундах
  end;

implementation

uses
  syncobjs, DateUtils, SysUtils, Consta, LoggerU, TestUnit;

{ TMyWriter }

procedure TMyWriter.Execute;
var
  n: TDateTime;
begin
  inherited;
  while not Terminated do begin
    Logger.Write(CreateText(15), CreateStatus); // Ћоггер записывает переданные сообщение и статус
    n := Now;
    while (not Terminated) and (MilliSecondsBetween(Now, n) < PeriodWrite) do Sleep(0); // "тревожно" спим, провер€€ Terminated
  end;
end;

{ TMyCleaner }

procedure TMyCleaner.Execute;
var
  n: TDateTime;
begin
  inherited;
  while not Terminated do begin
    n := Now;
    while (not Terminated) and (MilliSecondsBetween(Now, n) < TimeClear) do Sleep(0); // "тревожно" спим, провер€€ Terminated
    Logger.Clear; // вежливо попросим Ћоггер почистить
  end;
end;

end.
