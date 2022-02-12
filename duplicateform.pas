unit DuplicateForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  ComCtrls, DuplicateFinderThread, ExamineForm, CommonDialogs;

type

  { TDForm }

  TDForm = class(TForm)
    AddDirButton: TButton;
    FindButton: TButton;
    DirCombo: TComboBox;
    DirGroup: TGroupBox;
    FindProgressBar: TProgressBar;
    ProgressLabel: TLabel;
    RemoveDirButton: TButton;
    DirectoryDialog: TSelectDirectoryDialog;
    SummaryGrid: TStringGrid;
    procedure AddDirButtonClick(Sender: TObject);
    procedure FindButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure RemoveDirButtonClick(Sender: TObject);
    procedure SummaryGridClick(Sender: TObject);
  private
    FinderThread: TDuplicateFinderThread;
    procedure GUICallback;
    function GetExtractedFileNames(list: TStrings): String;
  public

  end;

var
  DForm: TDForm;

implementation

{$R *.lfm}

{ TDForm }

procedure TDForm.FindButtonClick(Sender: TObject);
var
  r: Integer;
begin
  if self.DirCombo.Items.Count < 1 then begin
    TCommonDialogs.ErrorNotify('No scan directories defined.', self.Caption);
    Exit;
  end;

  if not String.Equals(self.FindButton.Caption, 'Cancel') then begin
    for r:=1 to self.SummaryGrid.RowCount-1 do begin
      self.SummaryGrid.DeleteRow(1);
    end;
    self.FinderThread.Free;
    self.FinderThread:= TDuplicateFinderThread.Create(self.DirCombo.Items, @self.GUICallback);
    self.FinderThread.Start;
    self.FindButton.Caption:= 'Cancel';
  end
  else begin
    self.FinderThread.Terminate;
  end;
end;

procedure TDForm.FormCreate(Sender: TObject);
begin
  self.FinderThread:= TDuplicateFinderThread.Create(self.DirCombo.Items, @self.GUICallback);
end;

procedure TDForm.FormDestroy(Sender: TObject);
begin
  self.FinderThread.Free;
end;

procedure TDForm.RemoveDirButtonClick(Sender: TObject);
begin
  if self.DirCombo.Items.Count = 0 then begin
    Exit;
  end
  else begin
    self.DirCombo.Items.Delete(self.DirCombo.ItemIndex);
    if self.DirCombo.Items.Count = 0 then begin
      self.DirCombo.Text:= String.Empty;
    end;
  end;
end;

procedure TDForm.AddDirButtonClick(Sender: TObject);
begin
  if self.DirectoryDialog.Execute then begin
    if DirectoryExists(self.DirectoryDialog.FileName) then begin
      self.DirCombo.Items.Add(self.DirectoryDialog.FileName);
      self.DirCombo.ItemIndex:= self.DirCombo.Items.Count-1;
    end;
  end;
end;

procedure TDForm.SummaryGridClick(Sender: TObject);
var
  selectedhash, filepath, extractednames: String;
  filelist: TStringList;
  ehf: TExamineHashForm;
begin
  if (self.SummaryGrid.RowCount < 2) or (self.SummaryGrid.Row = 0) then begin
    Exit;
  end;

  selectedhash:= self.SummaryGrid.Cells[0, self.SummaryGrid.Row];
  filelist:= self.FinderThread.GetHashDict[selectedhash];

  ehf:= TExamineHashForm.Create(self);
  for filepath in filelist do begin
    ehf.DupeList.Items.Add(filepath);
  end;

  ehf.ShowModal;
  if ehf.DupeList.Count < 2 then begin
    self.SummaryGrid.DeleteRow(self.SummaryGrid.Row);
    filelist:= self.FinderThread.GetHashDict[selectedhash];
    filelist.Free;
    self.FinderThread.GetHashDict.Remove(selectedhash);
  end
  else begin
    filelist:= self.FinderThread.GetHashDict[selectedhash];
    filelist.Clear;
    filelist.AddStrings(ehf.DupeList.Items);
    extractednames:= self.GetExtractedFileNames(filelist);
    self.SummaryGrid.Cells[1, self.SummaryGrid.Row]:= extractednames;
  end;

end;

procedure TDForm.GUICallback;
var
  list: TStringList;
  hash, extractednames: String;
begin
  self.FindProgressBar.Position:= self.FinderThread.GetPercentDone;
  self.ProgressLabel.Caption:= self.FinderThread.GetProgressMessage;
  if self.FinderThread.GetPercentDone = 100 then begin
    if self.FinderThread.Cancel then begin
      TCommonDialogs.ErrorNotify(self.FinderThread.GetProgressMessage, self.Caption);
    end
    else begin
      for hash in self.FinderThread.GetHashDict.Keys do begin
        list:= self.FinderThread.GetHashDict[hash];
        if list.Count > 1 then begin
          extractednames:= self.GetExtractedFileNames(list);
          self.SummaryGrid.InsertRowWithValues(1, [hash, extractednames]);
        end;
      end;
      TCommonDialogs.InfoNotify(self.FinderThread.GetProgressMessage, self.Caption);
    end;
    self.FindButton.Caption:= 'Find';
    self.ProgressLabel.Caption:= 'Ready';
    self.FindProgressBar.Position:= 0;
  end;
end;

function TDForm.GetExtractedFileNames(list: TStrings): String;
var
  filepath: String;
  extractedname, extractednames: String;
begin
  for filepath in list do begin
    extractedname:= ExtractFileName(filepath);
    if extractednames.Length = 0 then begin
      extractednames:= extractedname;
    end
    else begin
      extractednames:= extractednames+', '+extractedname;
    end;
  end;
  Exit(extractednames);
end;

end.

