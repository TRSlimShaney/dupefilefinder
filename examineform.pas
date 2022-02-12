unit ExamineForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids;

type

  { TExamineHashForm }

  TExamineHashForm = class(TForm)
    DeleteButton: TButton;
    DupeGroup: TGroupBox;
    DupeList: TListBox;
    procedure DeleteButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private

  public
    DupesRemoved: TStringList;
  end;

var
  ExamineHashForm: TExamineHashForm;

implementation

{$R *.lfm}

{ TExamineHashForm }

procedure TExamineHashForm.DeleteButtonClick(Sender: TObject);
var
  filepath: String;
begin
  filepath:= self.DupeList.GetSelectedText;
  if FileExists(filepath) then begin
    DeleteFile(filepath);
  end;
  self.DupesRemoved.Add(filepath);
  self.DupeList.DeleteSelected;
end;

procedure TExamineHashForm.FormCreate(Sender: TObject);
begin
  self.DupesRemoved:= TStringList.Create;
end;

procedure TExamineHashForm.FormDestroy(Sender: TObject);
begin
  self.DupesRemoved.Free;
end;

end.

