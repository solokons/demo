////////////////////////////////////////////////////////
//                                                    //
//                       ������                       //
//                                                    //
// � ������� ������� "����������� �������� ������..." //
// ����������� �� ��������, ������� ����� ����������  //
// ������ ��������������, ������ ��� ���� ����� ����� //
//                                                    //
// ������ ����� ������ � �������                      //
// ������������ ��������� ���                         //
// ������-��������: �������� ���������, ������        //
// �����-����������: ��������� ����                   //
//                                                    //
//        � �������� MVC ��� �������� Model           //
//                                                    //
////////////////////////////////////////////////////////

unit ThreadsU;

interface

uses
  Classes;

type
  // �����-��������, ���������� ��������� � ������, � ������������ ��������� ������� �� ��������
  TMyWriter = class(TThread)
  protected
    procedure Execute; override;
  public
    PeriodWrite: Cardinal; // ������ �������� ��������� � �������������
  end;

  // �����-����������, ������������ ��������� ������� ������� ���������� ������
  TMyCleaner = class(TThread)
  protected
    procedure Execute; override;
  public
    TimeClear: Cardinal; // ������ ������� ���-����� �� ���������� ��������� � �������������
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
    Logger.Write(CreateText(15), CreateStatus); // ������ ���������� ���������� ��������� � ������
    n := Now;
    while (not Terminated) and (MilliSecondsBetween(Now, n) < PeriodWrite) do Sleep(0); // "��������" ����, �������� Terminated
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
    while (not Terminated) and (MilliSecondsBetween(Now, n) < TimeClear) do Sleep(0); // "��������" ����, �������� Terminated
    Logger.Clear; // ������� �������� ������ ���������
  end;
end;

end.
