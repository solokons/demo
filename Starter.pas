//////////////////////////////////////////////////////
//                                                  //
//          МОДУЛЬ ЗАПУСКА И ОСТАНОВКИ              //
//                                                  //
//      этот модуль знает о Логгере и потоках       //
// он их запускает, а по окончании работы программы //
//      останавливает и освобождает ресурсы         //
//                                                  //
//          в паттерне MVC это Controller           //
//                                                  //
//////////////////////////////////////////////////////

unit Starter;

interface

implementation

uses
  Classes, syncobjs, sysutils, System.Generics.Collections, inifiles, Consta, LoggerU, ThreadsU;

const
  // если строка-константа используется в коде более одного (двух, трех, и т.д., нужное подчеркнуть) раза, то она достойна отдельного объявления
  cMainSectionIniFile    = 'main';
  cWritersSectionIniFile = 'writers';
  tmpPrefix              = 'lasdjflasldfjksdflasldf_';

var
  sWriters        : TStringList; // нужен будет, чтобы считать всю секцию времен жизни потоков-писателей из конфига
                                 // т.к. мы заранее не знаем сколько в конфиге потоков, и ключи у них произвольные
  IniFile         : TIniFile;
  f               : TextFile;    // нужо для того, чтобы проверить допустимость имени лог-файла взятого из конфига
  s, fn           : String;
  w               : TMyWriter;
  c               : TMyCleaner;
  i, k, th_cntr   : Integer;
  aWritePeriods   : array of Cardinal; // периоды записи в миллисекундах для потоков-писателей, длинна массива = количество потоков-писателей
  Writers         : TObjectList<TMyWriter>; // список для хранения потоков-писателей (нужен, чтобы по завершении программы завершить потоки)
  // был вопрос что использовать для освобождения потоков: TList или TObjectList?
  // с одной стороны код на строчку короче,
  // а с другой, ради единственной операции заюзывать доп.модуль System.Generics.Collections
  // TObjectList был выбран для демонстрации владения дженериками

initialization

// все константы у нас типизированные, перезапишем их значение, если оно найдется в конфиге
// с массивом периодов записи потоков-писателей чуть сложнее, т.к. длинну массива констант менять нельзя
// а в конфиге количество потоков может отличаться от длинны массива констант, поэтому используем динамический массив aWritePeriods

fn := ParamStr(0); // получим полный путь к экзешнику

fn := ExtractFileDir(fn) + '\_config.ini';                // сделаем полный путь к файлу конфига
if FileExists(fn) then begin                              // если такой файл имеется, то работаем
  IniFile  := TIniFile.Create(fn);                        // создадим конфиг
  sWriters := TStringList.Create;                         // создадим список для чтения секции потоков-писателей
  try
    // прочтем предполагаемое имя файла из конфига, если не прочлось, то вернем запрещенный для имен файлов символ
    s := IniFile.ReadString(cMainSectionIniFile, 'LogFileName', '*');
    Assign(f, tmpPrefix + s);                             // проверим, допустимо ли полученное имя файла
    try                                                   // попытаемся
      Rewrite(f);                                         // создать тестовый файл с именем содержащим этот фрагмет
      Close(f);                                           // если получилось, то все в порядке, закроем тестовый файл
      DeleteFile(tmpPrefix + s);                          // удалим тестовый файл
      сLogFileName := s;                                  // преприсвоим константу с именем лог-файла
    except end;                                           // а если не получилось - ну не получилось, тогда остается константа
    k := IniFile.ReadInteger(cMainSectionIniFile, 'TimeClear', cTimeClear);     // получаем из конфига период очистки
    if k > 0 then cTimeClear := k;                                              // если положительное - переприсваиваем
    k := IniFile.ReadInteger(cMainSectionIniFile, 'TimeMessage', cTimeMessage); // получаем из конфига время жизни сообщения
    if k > 0 then cTimeMessage := k;                                            // если положительное - переприсваиваем
    // мы заранее не знаем, сколько в конфиге прописано потоков и как устроены имена их ключей
    IniFile.ReadSection(cWritersSectionIniFile, sWriters);// прочтем целиком всю секцию
    if sWriters.Count > 0 then begin                      // если что-нибудь есть
      SetLength(aWritePeriods, sWriters.Count);           // установим длину динамического массива максимально возможной
      th_cntr := 0;                                       // обнулим счетчик реально обнаруженных потоков
      for i := 0 to sWriters.Count-1 do begin             // побежали по секции
        try
          // получаем из конфига период записи очередного потока-писателя, и если значение не целое число - вернем -1
          k := IniFile.ReadInteger(cWritersSectionIniFile, sWriters[i], -1);
          if k > 0 then begin                             // если полученное число - положительное
            aWritePeriods[th_cntr] := k;                  // это реально поток, сохраним его период записи
            inc(th_cntr);                                 // инкременируем счетчик реально обнаруженных потоков
          end;
        except end;
      end;                                                // добежали до конца секции
      SetLength(aWritePeriods, th_cntr);                  // усечем массив до реально обнаруженного количества потоков-писателей
    end;
  finally                                                 // не смотря ни на что
    sWriters.Free;                                        // освободим секцию конфига потоков-писателей
    IniFile.Free;                                         // освободим конфиг
  end;
end;

if Length(aWritePeriods) < 1 then begin                   // если оказалось, что в конфиге не нашлось ни одного потока-писателя, то
  SetLength(aWritePeriods, High(cWritePeriods) + 1);      // заполним массив с периодами записи потоков-писателей из массива констант
  for i := Low(aWritePeriods) to High(aWritePeriods) do aWritePeriods[i] := cWritePeriods[i];
end;

Logger := TLogger.Create(сLogFileName);                   // создадим Логгер

Writers := TObjectList<TMyWriter>.Create;                 // создадим список - хранитель потоков-писателей
for i := Low(aWritePeriods) to High(aWritePeriods) do begin  // по количеству потоков-писателей
  w := TMyWriter.Create(true);                            // создадим поток-писатель
  w.PeriodWrite := aWritePeriods[i];                      // установим этому потоку свой период записывания
  w.Resume;                                               // запустим
  Writers.Add(w);                                         // добавим в список, чтобы потом корректно высвободить ресурс
end;

c := TMyCleaner.Create(true);                             // создадим поток-чистильщик
c.TimeClear  := cTimeClear;                               // установим период чистки
c.FreeOnTerminate := true;                                // выставим самоуничтожение после остановки
c.Resume;                                                 // запустим

finalization

c.Terminate;                                              // остановим поток-чистильщик - он самоуничтожится
for i := 0 to Writers.Count - 1 do                        // по количеству потоков-писателей
  TMyWriter(Writers.Items[i]).Terminate;                  // остановим поток-писатель
Writers.Free;                                             // список свое дело сделал - освобождаем, потоки-писатели освободятся автоматически;
Logger.Free;                                              // освободим Логгер

end.
