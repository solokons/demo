//////////////////////////////////////////////////
//                                              //
//        ������ ������������ ����������        //
//                                              //
//  ���� ������ �� ���� �� ����� � �������      //
//  �� ������ ��������� ������-�� �������       //
//  � ���� ������ �������� ��, ����� ��� �����  //
//                                              //
//          � �������� MVC ��� View             //
//                                              //
//////////////////////////////////////////////////

unit FormaU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ThreadsU, Vcl.StdCtrls;

procedure RefreshMemo(s: String);

type
  TForma = class(TForm)
    Memo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public

  end;

var
  Forma: TForma;

implementation

uses
  LoggerU;

{$R *.dfm}


procedure TForma.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Logger.OnRefreshGraficInterface := nil; // �������, ������ ��� ������ ������ ������, � ������ ��� ����� ���������� ��������
  Caption := 'Closing...';
end;

procedure TForma.FormCreate(Sender: TObject);
begin
  // ����� ������� ���������, ������� �� ����� ��������, ����� � ���������� ������������ ���������, ���������� � ������
  Logger.OnRefreshGraficInterface := RefreshMemo;
end;

procedure RefreshMemo(s: String);
begin
  Forma.Memo.Lines.BeginUpdate;
  Forma.Memo.Clear;
  Forma.Memo.Text := s;
  Forma.Memo.Lines.EndUpdate;
end;

end.
