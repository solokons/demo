//////////////////////////////////////////////////
//                                              //
//        ћќƒ”Ћ№ √–ј‘»„≈— ќ√ќ »Ќ“≈–‘≈…—ј        //
//                                              //
//  этот модуль ни чего не знает о потоках      //
//  он отдает процедуру какому-то Ћоггеру       //
//  а этот Ћоггер вызывает ее, когда ему нужно  //
//                                              //
//          в паттерне MVC это View             //
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
  Logger.OnRefreshGraficInterface := nil; // занулим, потому что писать больше некуда, а потоки еще могут продолжать работать
  Caption := 'Closing...';
end;

procedure TForma.FormCreate(Sender: TObject);
begin
  // дадим Ћоггеру процедуру, которую он будет вызывать, чтобы в интерфейсе отобразились сообщени€, хран€щиес€ в пам€ти
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
