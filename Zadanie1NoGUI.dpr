//////////////////////////////////////////////////
//                                              //
//     ������ ��� ������������ ����������       //
//                                              //
//       � �������� MVC ��� Controller          //
//                                              //
//////////////////////////////////////////////////

// ��� �������� ������������ ����� ��������� � ���������� t

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
  Writeln('��� ���������� ������ �������� ����� ����� ������ ENTER');
  Writeln('������� ENTER');
  Readln;
  // ����� ������� ���������, ������� �� ����� �������� ��� ����������� ��������� ���������� � ������
  Logger.OnRefreshGraficInterface := Show;
  Readln;
end.
