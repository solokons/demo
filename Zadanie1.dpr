// ������� � 1
// ��������:  10 ����� 2021 �. � 13:47
// ���������: 13 ����� 2021 �. � 07:35

// ��� �������� ������������ ����� ��������� � ���������� t

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
