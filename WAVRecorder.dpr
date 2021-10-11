program WAVRecorder;

uses
  Forms,
  WAVRecorderU in 'WAVRecorderU.pas' {frmWAVRecorder};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmWAVRecorder, frmWAVRecorder);
  Application.Run;
end.
