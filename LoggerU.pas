//////////////////////////////////////////////////////
//                                                  //
//                     ������                       //
//                                                  //
//          ������ �� ���� �� � ��� �� �����        //
//            ��� �� ������ ����������              //
//      ������� ���� ����������� �������� ���       //
//          ����� � �������� ��� ������             //
//                                                  //
//         �������� MVC ��� �������� Model          //
//                                                  //
//////////////////////////////////////////////////////

unit LoggerU;

interface

uses
  Windows, syncobjs, classes;

const
  cSeparator = '    ' + #$9;          // �����������, ����������� ���������, ������ ������������� ������ � �����
  cDTFormat  = 'dd.mm.yyyy hh:mm:ss'; // ������ ����-������� ��� ������ � ���-���� (����� ���� ������������� ������)
  cMessageListCapacity = 10;          // ������� ��������� ��������� ������ ������ ������� � ������

type
// ��� ���������, ������� �������� ���������, ���������� � ������, � ���������, ���� ������� �����
TRefreshGraficInterface = procedure(s: String);

TLogger = class
private
  MessageList: TStringList;           // ������ ��� ��������� 10 ���������
  CSM        : TCriticalSection;      // ����������� ������ ��� ������ ������� � ������
  CSF        : TCriticalSection;      // ����������� ������ ��� ������ ������� � ���-�����
  CSI        : TCriticalSection;      // ����������� ������ ��� ������ ���������� ����������
  // ���, �� ������� ������, � ������������, ����� ���������... "����� ������" - ��� �����
public
  LogFileName:   String;              // ��� ���-�����
  OnRefreshGraficInterface: TRefreshGraficInterface; // ���� ����� �����-�� ���������, �� �� �������� ���� ���� ���������
  constructor Create(logfile_name: String);
  destructor Destroy; override;
  procedure Write(TextMessage: String; StatusMessage: String); // ������ � ���-����;
  procedure Clear;                    // ������� �����;
end;

var
  Logger:  TLogger;                   // ������ - ������� ������ ������ � 1

implementation

uses
  sysutils, DateUtils, Consta;

{ TLogger }

procedure TLogger.Clear;
// ������ ������� ���������:
// ��������� � ���-����� ���������� ������������� ������ ���� �� ����������� ������� ��������
// ������ ����� �������� �� ����� ���-�����, ������� ���� ��������� ������
// ����� ��������, ������� ������� �� �������� ������� �� �������� ���-�� �����
// ����� ������� �� ��������� ��� ������ �� ������, ��������� ���������� ����� ���-�����
// �� ��������� ����, ������ ���-����, � ����������� ��������� ���� � ���-����
const
  TmpFileName = 'i9psoafar21vbqzqya0.txt';  // ��� ��� ���������� �����
var
  o, n: TextFile;
  s, d: String;
  b: Boolean;
  dt, nd: TDateTime;
  mb: Int64;
begin
  AssignFile(o, LogFileName);                 // ����������� � ���-������
  if not FileExists(LogFileName) then exit;   // ���� ���-����� ���, �� � ������ ������ - �������
  // ����� �������� � ��������
  AssignFile(n, TmpFileName);                 // ����������� � ��������� ������
  CSF.Enter;                                  // ��������� ������ � ���-����� ��� ���� ���������
  try
    Reset(o);                                 // ��������� ���-���� �� ������
    Rewrite(n);                               // ����������� ��������� ���� �� ������
    b := true; // ���� b ����������� � true �� ����� �������� �� ������ �������� ������ � �� ����� �������� ��� ������ � �������� ���-����, ������ ��� ������ ������
    nd := Now();                              // ���������� ������� ������
    try
      while not Eof(o) do begin               // �������� �� ���-�����
        Readln(o, s);                         // ������� ������
        if b then begin                       // ���� ������������, ��� ��������� ������ ������
          // �� �������� ������������� �� ��� ������?
          // ������ �������� ������ ������� � ������� cDTFormat � ����� ������, ������� ����� ���������
          d := Copy(s, Length(s) - Length(cDTFormat) + 1, Length(cDTFormat));
          dt := StrToDateTime(d);             // �����������
          mb := MinutesBetween(nd, dt);       // ����� ������� ����� �������� �������� � ������� � �������
          b := mb >= cTimeMessage;            // ��� ������ ��������� �� ������ ������ b ������������ � false
          // � � ����� ������� �� �����, ��� ���� ������ ������� ��� � �������� ������� �������� ������ ������ �� �����
        end;
        if not b then Writeln(n, s);          // ���� ������ �� ������, �� ����� �� �������� ����
      end;
    finally
      CloseFile(o);
      CloseFile(n);
    end;
    // ���� ��������� �������� � ���������� t, �� ��� �������� �������� ������������ ����������������
    // ��������� ��� ����������� � ��������� "��" (_bef_) � "�����" (_aft_);
    if ParamStr(1) = 't' then begin
      CopyFile(PWideChar(LogFileName), PWideChar(FormatDateTime('hh_mm_ss', nd) + '_bef_' + LogFileName), false);
      CopyFile(PWideChar(TmpFileName), PWideChar(FormatDateTime('hh_mm_ss', nd) + '_aft_' + LogFileName), false);
    end;
    DeleteFile(LogFileName);                  // ������� ������ ���-����
    RenameFile(TmpFileName, LogFileName);     // ��������� ���� ��������������� � ���-����
  finally
    CSF.Leave;                                // ��������� ������ � ���-�����
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
  CSM.Enter;                                         // ��������� ������ � ������
  try                                                // �������� � �������
    if MessageList.Count = cMessageListCapacity then // ���� ��������� � ������ ��� ������, ��
      MessageList.Delete(cMessageListCapacity - 1);  // ������� ����� ������, �� ���� ���������
    MessageList.Insert(0, TextMessage);              // ����� ��������� � ������
  finally                                            // �� ������ �� �� ����� ������������
    CSM.Leave;                                       // ��������� ������ � ������
  end;
  s := TextMessage + cSeparator + StatusMessage + cSeparator + IntToStr(GetCurrentThreadId)
    + cSeparator + FormatDateTime(cDTFormat, Now()); // ������� ������, ������� ������� � ���-����
  CSF.Enter;                                         // ��������� ������ � ���-�����
  try
    AssignFile(f, LogFileName);                      // ����������� � ���-������
    if FileExists(LogFileName)                       // ���� ���-���� �������
      then Append(f)                                 // �� ��������� ��� �� ����������
      else Rewrite(f);                               // ����� ������� � ��������� �� ������
    try                                              // ��������
      Writeln(f, s);                                 // �������� ������ � ���-����
    finally                                          // �� ������ �� �� ����� ������������
      CloseFile(f);                                  // ��������� ���-����
    end;
  finally                                            // �� ������ �� �� ����� ������������
    CSF.Leave;                                       // ��������� ������ � ���-�����
  end;
  CSI.Enter;                                         // ��������� ������ � ���������� ����������
  try
    if Assigned(OnRefreshGraficInterface) then       // ���� ������-�� ���������� �����
      OnRefreshGraficInterface(MessageList.Text);    // �� �������� ��� ������ ��� �����������
  finally                                            // �� ������ �� �� ����� ������������
    CSI.Leave;                                       // ��������� ������ � ���������� ����������
  end;
end;

end.
