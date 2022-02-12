unit DuplicateFinderThread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, generics.collections, md5, FileUtil;

  type
    TGUICallback = procedure of Object;
    TDuplicateFinderThread = class(TThread)
      private type
        THashDict = specialize TObjectDictionary<String, TStringList>;
      private
        HashDict: THashDict;
        SearchDirs: TStrings;
        GUICallback: TGUICallback;
        PercentDone: Integer;
        ProgressMessage: String;
        procedure UpdatePercent(message: String; percent: Integer);
      protected
        procedure Execute; override;
      public
        Cancel: Boolean;
        property GetPercentDone: Integer read PercentDone;
        property GetProgressMessage: String read ProgressMessage;
        property GetHashDict: THashDict read HashDict;
        constructor Create(dirs: TStrings; guicb: TGUICallback);
        destructor Destroy; override;
  end;

implementation

constructor TDuplicateFinderThread.Create(dirs: TStrings; guicb: TGUICallback);
begin
  inherited Create(True);
  self.FreeOnTerminate:= False;

  self.HashDict:= THashDict.Create;
  self.SearchDirs:= dirs;
  self.GUICallback:= guicb;
  self.PercentDone:= 0;
  self.Cancel:= False;
end;

destructor TDuplicateFinderThread.Destroy;
var
  list: TStringList;
begin
  for list in self.HashDict.Values do begin
    list.Free;
  end;
  self.HashDict.Free;
  inherited;
end;

procedure TDuplicateFinderThread.Execute;
var
  filehash, filedir, filepath: String;
  filelist, duplicates: TStringList;
  numberofdupes: Integer = 0;
begin
  for filedir in self.SearchDirs do begin
    filelist:= FindAllFiles(filedir, '*');

    for filepath in filelist do begin
      self.UpdatePercent('Examining file: '+filepath, 50);

      filehash:= MD5Print(MD5File(filepath));

      if not self.HashDict.ContainsKey(filehash) then begin
        duplicates:= TStringList.Create;
        duplicates.Add(filepath);
        self.HashDict.Add(filehash, duplicates);
      end
      else begin
        duplicates:= self.HashDict[filehash];
        duplicates.Add(filepath);
        Inc(numberofdupes, 1);
      end;

      if self.Terminated then begin
        self.UpdatePercent('Cancelling...', 90);
        break;
      end;

    end;
    filelist.Free;

    if self.Terminated then begin
      self.UpdatePercent('Cancelling...', 90);
      break;
    end;

  end;

  if self.Terminated then begin
    self.Cancel:= True;
    self.UpdatePercent('Cancelled.', 100);
  end
  else begin
    self.UpdatePercent('Finished. '+IntToStr(numberofdupes)+' duplicate files found.', 100);
  end;
  self.ReturnValue:= 0;
end;

procedure TDuplicateFinderThread.UpdatePercent(message: String; percent: Integer);
begin
  self.PercentDone:= percent;
  self.ProgressMessage:= message;
  self.Synchronize(self.GUICallback);
end;

end.

