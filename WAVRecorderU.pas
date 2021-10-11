unit WAVRecorderU;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ActnList, ImgList, Buttons, ComCtrls, Menus, ToolWin;

type
  TRecordState = (rsStopped, rsRecording);

  TfrmWAVRecorder = class(TForm)
    dlgSave: TSaveDialog;
    Button1: TBitBtn;
    Button2: TBitBtn;
    ActionList1: TActionList;
    actRecord: TAction;
    actStop: TAction;
    ImageList: TImageList;
    StatusBar: TStatusBar;
    MainMenu1: TMainMenu;
    ToolBar1: TToolBar;
    mniFile: TMenuItem;
    mniFileRecord: TMenuItem;
    mniFileStop: TMenuItem;
    mniAudio: TMenuItem;
    actAudioProps: TAction;
    actVolume: TAction;
    AudioProperties1: TMenuItem;
    RecordingVolume1: TMenuItem;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    actAbout: TAction;
    Help1: TMenuItem;
    About1: TMenuItem;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    procedure actRecordExecute(Sender: TObject);
    procedure actRecordUpdate(Sender: TObject);
    procedure actStopExecute(Sender: TObject);
    procedure actStopUpdate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure actAudioPropsExecute(Sender: TObject);
    procedure actVolumeExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
  private
    { Private declarations }
  public
    State: TRecordState; //defaults to the 0 value, i.e. rsStopped
    FileName: TFileName;
  end;

var
  frmWAVRecorder: TfrmWAVRecorder;

implementation

{$R *.dfm}

uses
  MMSystem, FileCtrl;

const
  mciOpenWav = 'open new type waveaudio alias WAVfile';
  mciSetWavAttrs = 'set WAVfile format tag pcm bitspersample 16 ' +
    'samplespersec 44100 channels 2 bytespersec 176400 alignment 4 wait';
  mciRecordWav = 'record WAVfile';
  mciStopWav = 'stop WAVfile';
  mciSaveWav = 'save WAVfile %s';
  mciCloseWav = 'close WAVfile';

type
  EMCIError = class(Exception);

procedure MCICheck(RetVal: MCIERROR);
var
  CErrMsg: array[0..1024] of Char;
  ErrMsg: String;
begin
  if (RetVal <> MMSYSERR_NOERROR) then
  begin
    ErrMsg := 'Unknown error code';
    if mciGetErrorString(RetVal, CErrMsg, SizeOf(CErrMsg)) then
      ErrMsg := CErrMsg;
    raise EMCIError.Create(ErrMsg)
  end
end;

function MsgDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; const Title: String = ''): TModalResult;
begin
  with CreateMessageDialog(Msg, DlgType, Buttons) do
    try
      Position := poMainFormCenter;
      if Title <> '' then
        Caption := Title;
      Result := ShowModal;
    finally
      Free;
    end;
end;

procedure TfrmWAVRecorder.actRecordExecute(Sender: TObject);
begin
  if dlgSave.Execute then
  begin
    MCICheck(mciSendString(mciOpenWav, nil, 0, 0));
    MCICheck(mciSendString(mciSetWavAttrs, nil, 0, 0));
    MsgDlg(Format('Press OK to start recording %s', [FileName]), mtInformation, [mbOk]);
    MCICheck(mciSendString(mciRecordWav, nil, 0, 0));
    State := rsRecording;
    FileName := dlgSave.FileName;
    StatusBar.SimpleText := MinimizeName(FileName, StatusBar.Canvas, StatusBar.ClientWidth)
  end
end;

procedure TfrmWAVRecorder.actRecordUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := State = rsStopped
end;

procedure TfrmWAVRecorder.actStopExecute(Sender: TObject);
var
  SaveCmd: String;
begin
  MCICheck(mciSendString(mciStopWav, nil, 0, 0));
  State := rsStopped;
  if Pos(#32, FileName) > 0 then
  begin
    //MCI requires quotes around file name/paths with spaces in
    FileName := '"' + Filename + '"';
    //MCI doesn't seem able to overwrite a filename with spaces in
    if FileExists(FileName) then
      DeleteFile(FileName)
  end;
  SaveCmd := Format(mciSaveWav, [FileName]);
  MCICheck(mciSendString(PChar(SaveCmd), nil, 0, 0));
  MCICheck(mciSendString(mciCloseWav, nil, 0, 0));
  FileName := '';
  StatusBar.SimpleText := ''
end;

procedure TfrmWAVRecorder.actStopUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := State = rsRecording
end;

procedure TfrmWAVRecorder.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if State = rsRecording then
  begin
    case MsgDlg('Still recording. Really close?', mtConfirmation, mbOKCancel) of
      mrOK:
        try
          actStop.Execute;
        except
          on E: Exception do
            Application.ShowException(E);
        end;
      mrCancel: CanClose := False;
    end
  end
end;

procedure TfrmWAVRecorder.actAudioPropsExecute(Sender: TObject);
begin
  WinExec('RunDll32.EXE MMSYS.CPL,ShowAudioPropertySheet', SW_SHOWNORMAL);
end;

procedure TfrmWAVRecorder.actVolumeExecute(Sender: TObject);
begin
  WinExec('sndvol32.exe -R', SW_SHOWNORMAL);
end;

procedure TfrmWAVRecorder.actAboutExecute(Sender: TObject);
begin
  MsgDlg(
    'A simple solution to piles of old records:'#13#13 +
    'Transfer them to WAV files with this'#13 +
    'application and then burn them onto CDs'#13 +
    'with your favourite CD burning software'#13#13 +
    'Make sure you use the Audio Properties to'#13 +
    'select the correct recording device and'#13 +
    'use the Volume control to set the correct'#13 +
    'audio input source and levels.'#13#13 +
    'Copyright © Brian Long, 2003'#13#13'Use as you need',
    mtInformation, [mbOk],
    'About The Delphi Clinic WAV Recorder')
end;

end.
