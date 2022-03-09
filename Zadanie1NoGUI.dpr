//////////////////////////////////////////////////
//                                              //
//     ВЕРСИЯ БЕЗ ГРАФИЧЕСКОГО ИНТЕРФЕЙСА       //
//                                              //
//       в паттерне MVC это Controller          //
//                                              //
//////////////////////////////////////////////////

// для удобства тестирования лучше запускать с параметром t

program Zadanie1NoGUI;

{$APPTYPE CONSOLE}

uses
  Consta in 'Consta.pas',
  LoggerU in 'LoggerU.pas',
  ThreadsU in 'ThreadsU.pas',
  TestUnit in 'TestUnit.pas',
  Starter in 'Starter.pas';

procedure Show(s: String);
begin
  Writeln(s);
end;

begin
  Writeln('Для завершения работы програмы нужно будет нажать ENTER');
  Writeln('Нажмите ENTER');
  Readln;
  // дадим Логгеру процедуру, которую он будет вызывать для отображения сообщений хранящихся в памяти
  Logger.OnRefreshGraficInterface := Show;
  Readln;
end.
