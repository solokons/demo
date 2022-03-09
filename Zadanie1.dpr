// Задание № 1
// Получено:  10 марта 2021 г. в 13:47
// Завершено: 13 марта 2021 г. в 07:35

// для удобства тестирования лучше запускать с параметром t

program Zadanie1;

uses
  Vcl.Forms,
  Consta in 'Consta.pas',
  TestUnit in 'TestUnit.pas',
  LoggerU in 'LoggerU.pas',
  ThreadsU in 'ThreadsU.pas',
  Starter in 'Starter.pas',
  FormaU in 'FormaU.pas' {Forma};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForma, Forma);
  Application.Run;
end.
