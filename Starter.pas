//////////////////////////////////////////////////////
//                                                  //
//          ������ ������� � ���������              //
//                                                  //
//      ���� ������ ����� � ������� � �������       //
// �� �� ���������, � �� ��������� ������ ��������� //
//      ������������� � ����������� �������         //
//                                                  //
//          � �������� MVC ��� Controller           //
//                                                  //
//////////////////////////////////////////////////////

unit Starter;

interface

implementation

uses
  Classes, syncobjs, sysutils, System.Generics.Collections, inifiles, Consta, LoggerU, ThreadsU;

const
  // ���� ������-��������� ������������ � ���� ����� ������ (����, ����, � �.�., ������ �����������) ����, �� ��� �������� ���������� ����������
  cMainSectionIniFile    = 'main';
  cWritersSectionIniFile = 'writers';
  tmpPrefix              = 'lasdjflasldfjksdflasldf_';

var
  sWriters        : TStringList; // ����� �����, ����� ������� ��� ������ ������ ����� �������-��������� �� �������
                                 // �.�. �� ������� �� ����� ������� � ������� �������, � ����� � ��� ������������
  IniFile         : TIniFile;
  f               : TextFile;    // ���� ��� ����, ����� ��������� ������������ ����� ���-����� ������� �� �������
  s, fn           : String;
  w               : TMyWriter;
  c               : TMyCleaner;
  i, k, th_cntr   : Integer;
  aWritePeriods   : array of Cardinal; // ������� ������ � ������������� ��� �������-���������, ������ ������� = ���������� �������-���������
  Writers         : TObjectList<TMyWriter>; // ������ ��� �������� �������-��������� (�����, ����� �� ���������� ��������� ��������� ������)
  // ��� ������ ��� ������������ ��� ������������ �������: TList ��� TObjectList?
  // � ����� ������� ��� �� ������� ������,
  // � � ������, ���� ������������ �������� ��������� ���.������ System.Generics.Collections
  // TObjectList ��� ������ ��� ������������ �������� �����������

initialization

// ��� ��������� � ��� ��������������, ����������� �� ��������, ���� ��� �������� � �������
// � �������� �������� ������ �������-��������� ���� �������, �.�. ������ ������� �������� ������ ������
// � � ������� ���������� ������� ����� ���������� �� ������ ������� ��������, ������� ���������� ������������ ������ aWritePeriods

fn := ParamStr(0); // ������� ������ ���� � ���������

fn := ExtractFileDir(fn) + '\_config.ini';                // ������� ������ ���� � ����� �������
if FileExists(fn) then begin                              // ���� ����� ���� �������, �� ��������
  IniFile  := TIniFile.Create(fn);                        // �������� ������
  sWriters := TStringList.Create;                         // �������� ������ ��� ������ ������ �������-���������
  try
    // ������� �������������� ��� ����� �� �������, ���� �� ��������, �� ������ ����������� ��� ���� ������ ������
    s := IniFile.ReadString(cMainSectionIniFile, 'LogFileName', '*');
    Assign(f, tmpPrefix + s);                             // ��������, ��������� �� ���������� ��� �����
    try                                                   // ����������
      Rewrite(f);                                         // ������� �������� ���� � ������ ���������� ���� �������
      Close(f);                                           // ���� ����������, �� ��� � �������, ������� �������� ����
      DeleteFile(tmpPrefix + s);                          // ������ �������� ����
      �LogFileName := s;                                  // ����������� ��������� � ������ ���-�����
    except end;                                           // � ���� �� ���������� - �� �� ����������, ����� �������� ���������
    k := IniFile.ReadInteger(cMainSectionIniFile, 'TimeClear', cTimeClear);     // �������� �� ������� ������ �������
    if k > 0 then cTimeClear := k;                                              // ���� ������������� - ���������������
    k := IniFile.ReadInteger(cMainSectionIniFile, 'TimeMessage', cTimeMessage); // �������� �� ������� ����� ����� ���������
    if k > 0 then cTimeMessage := k;                                            // ���� ������������� - ���������������
    // �� ������� �� �����, ������� � ������� ��������� ������� � ��� �������� ����� �� ������
    IniFile.ReadSection(cWritersSectionIniFile, sWriters);// ������� ������� ��� ������
    if sWriters.Count > 0 then begin                      // ���� ���-������ ����
      SetLength(aWritePeriods, sWriters.Count);           // ��������� ����� ������������� ������� ����������� ���������
      th_cntr := 0;                                       // ������� ������� ������� ������������ �������
      for i := 0 to sWriters.Count-1 do begin             // �������� �� ������
        try
          // �������� �� ������� ������ ������ ���������� ������-��������, � ���� �������� �� ����� ����� - ������ -1
          k := IniFile.ReadInteger(cWritersSectionIniFile, sWriters[i], -1);
          if k > 0 then begin                             // ���� ���������� ����� - �������������
            aWritePeriods[th_cntr] := k;                  // ��� ������� �����, �������� ��� ������ ������
            inc(th_cntr);                                 // ������������� ������� ������� ������������ �������
          end;
        except end;
      end;                                                // �������� �� ����� ������
      SetLength(aWritePeriods, th_cntr);                  // ������ ������ �� ������� ������������� ���������� �������-���������
    end;
  finally                                                 // �� ������ �� �� ���
    sWriters.Free;                                        // ��������� ������ ������� �������-���������
    IniFile.Free;                                         // ��������� ������
  end;
end;

if Length(aWritePeriods) < 1 then begin                   // ���� ���������, ��� � ������� �� ������� �� ������ ������-��������, ��
  SetLength(aWritePeriods, High(cWritePeriods) + 1);      // �������� ������ � ��������� ������ �������-��������� �� ������� ��������
  for i := Low(aWritePeriods) to High(aWritePeriods) do aWritePeriods[i] := cWritePeriods[i];
end;

Logger := TLogger.Create(�LogFileName);                   // �������� ������

Writers := TObjectList<TMyWriter>.Create;                 // �������� ������ - ��������� �������-���������
for i := Low(aWritePeriods) to High(aWritePeriods) do begin  // �� ���������� �������-���������
  w := TMyWriter.Create(true);                            // �������� �����-��������
  w.PeriodWrite := aWritePeriods[i];                      // ��������� ����� ������ ���� ������ �����������
  w.Resume;                                               // ��������
  Writers.Add(w);                                         // ������� � ������, ����� ����� ��������� ����������� ������
end;

c := TMyCleaner.Create(true);                             // �������� �����-����������
c.TimeClear  := cTimeClear;                               // ��������� ������ ������
c.FreeOnTerminate := true;                                // �������� ��������������� ����� ���������
c.Resume;                                                 // ��������

finalization

c.Terminate;                                              // ��������� �����-���������� - �� ���������������
for i := 0 to Writers.Count - 1 do                        // �� ���������� �������-���������
  TMyWriter(Writers.Items[i]).Terminate;                  // ��������� �����-��������
Writers.Free;                                             // ������ ���� ���� ������ - �����������, ������-�������� ����������� �������������;
Logger.Free;                                              // ��������� ������

end.
