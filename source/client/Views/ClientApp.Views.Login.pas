unit ClientApp.Views.Login;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.Actions,
  FMX.ActnList,
  FMX.StdActns,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.DialogService,
  FMX.Edit,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Ani,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.EventsDriven.Attributes,
  Fido.EventsDriven.Subscriber.Intf,

  Fido.Gui.Binding.Attributes,
  Fido.Gui.Types,
  Fido.Gui.Fmx.Binding,

  FidoApp.Messages,

  ClientApp.Types,
  ClientApp.Messages,
  ClientApp.Views.Login.Intf,
  ClientApp.ViewModels.Login.Intf;

type
  TLoginView = class(TForm, ILoginView)
    lblUsername: TLabel;
    lblPassword: TLabel;
    [BidirectionalToObservableBinding('Username', 'Text', 'OnExit')]
    edtUsername: TEdit;
    [BidirectionalToObservableBinding('Password', 'Text', 'OnExit')]
    edtPassword: TEdit;
    [BidirectionalToObservableBinding('RepeatedPassword', 'Text', 'OnExit')]
    edtRepeatPassword: TEdit;
    [MethodToActionBinding('Run', oeetAfter)]
    btnLogin: TButton;
    [MethodToActionBinding('Close', oeetAfter)]
    BtnBack: TButton;
    [MethodToActionBinding('SwitchAction', oeetAfter)]
    cbSignup: TCheckBox;
    alLogin: TActionList;
    actClose: TAction;
    lblRepeatPassword: TLabel;
    lblFirstName: TLabel;
    [BidirectionalToObservableBinding('FirstName', 'Text', 'OnExit')]
    edtFirstName: TEdit;
    lblLastName: TLabel;
    [BidirectionalToObservableBinding('LastName', 'Text', 'OnExit')]
    edtLastName: TEdit;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actCloseExecute(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    FSubscriber: IEventsDrivenSubscriber;
    FViewModel: ILoginViewModel;
    FAction: TLoginViewAction;
  public
    constructor Create(const Subscriber: IEventsDrivenSubscriber; const ViewModel: ILoginViewModel); reintroduce;

    [TriggeredByEvent('LoginViewModel', VIEW_BUSY_MESSAGE)]
    procedure OnBusyChange(const Busy: Boolean);
    [TriggeredByEvent('LoginViewModel', LOGIN_FAILED_MESSAGE)]
    procedure OnLoginFailed(const Message: string);
    [TriggeredByEvent('LoginViewModel', TOKEN_CHANGED_MESSAGE)]
    procedure OnLoginSuccessful;
    [TriggeredByEvent('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED)]
    procedure OnChangeAction(const Action: TLoginViewAction);
  end;

implementation

{$R *.fmx}

{ TLoginView }

procedure TLoginView.actCloseExecute(Sender: TObject);
begin
  Self.Close;
end;

constructor TLoginView.Create(
  const Subscriber: IEventsDrivenSubscriber;
  const ViewModel: ILoginViewModel);
begin
  inherited Create(nil);
  FSubscriber := Utilities.CheckNotNullAndSet(Subscriber, 'Subscriber');
  FViewModel := Utilities.CheckNotNullAndSet(ViewModel, 'ViewModel');
  FAction := TLoginViewAction.Login;

  Guibinding.Setup<ILoginViewModel, TLoginView>(FViewModel, Self);
  Guibinding.MethodsSetup<ILoginViewModel, TLoginView>(FViewModel, Self);

  FSubscriber.RegisterConsumer(Self);

  Self.ClientHeight := 113;
  lblRepeatPassword.Opacity := 0;
  lblRepeatPassword.SendToBack;
  edtRepeatPassword.Opacity := 0;
  edtRepeatPassword.SendToBack;

  lblFirstName.Opacity := 0;
  lblFirstName.SendToBack;
  edtFirstName.Opacity := 0;
  edtFirstName.SendToBack;

  lblLastName.Opacity := 0;
  lblLastName.SendToBack;
  edtLastName.Opacity := 0;
  edtLastName.SendToBack;
end;

procedure TLoginView.FormActivate(Sender: TObject);
begin
  edtUsername.SetFocus;
end;

procedure TLoginView.FormClose(
  Sender: TObject;
  var Action: TCloseAction);
begin
  FViewModel.Close;
  Action := TCloseAction.caFree;
end;

procedure TLoginView.OnBusyChange(const Busy: Boolean);
begin
  if not Assigned(edtUsername) then
    Exit;

  edtUsername.Enabled := not Busy;
  edtPassword.Enabled := not Busy;
  edtRepeatPassword.Enabled := not Busy;
  edtFirstName.Enabled := not Busy;
  edtLastName.Enabled := not Busy;
  btnLogin.Enabled := not Busy;
  BtnBack.Enabled := not Busy;
  cbSignup.Enabled := not Busy;
end;

procedure TLoginView.OnChangeAction(const Action: TLoginViewAction);
begin
  FAction := Action;
  if FAction = TLoginViewAction.Signup then
  begin
    TThread.Synchronize(nil,
      procedure
      begin
        Self.ClientHeight := 207;
      end);
      TAnimator.AnimateFloat(cbSignup, 'Position.Y', 173);
      TAnimator.AnimateFloat(btnLogin, 'Position.Y', 170);
      TAnimator.AnimateFloat(BtnBack, 'Position.Y', 170);
      TAnimator.AnimateFloat(lblRepeatPassword, 'Opacity', 1);
      TAnimator.AnimateFloat(edtRepeatPassword, 'Opacity', 1);
      TAnimator.AnimateFloat(lblFirstName, 'Opacity', 1);
      TAnimator.AnimateFloat(edtFirstName, 'Opacity', 1);
      TAnimator.AnimateFloat(lblLastName, 'Opacity', 1);
      TAnimator.AnimateFloat(edtLastName, 'Opacity', 1);

    btnLogin.Text := 'Signup';
    Self.Caption := 'Please signup';
    edtRepeatPassword.Enabled := True;
  end
  else
  begin
    TAnimator.AnimateFloat(cbSignup, 'Position.Y', 79);
    TAnimator.AnimateFloat(btnLogin, 'Position.Y', 76);
    TAnimator.AnimateFloat(BtnBack, 'Position.Y', 76);
    TAnimator.AnimateFloat(lblRepeatPassword, 'Opacity', 0);
    TAnimator.AnimateFloat(edtRepeatPassword, 'Opacity', 0);
    TAnimator.AnimateFloat(lblFirstName, 'Opacity', 0);
    TAnimator.AnimateFloat(edtFirstName, 'Opacity', 0);
    TAnimator.AnimateFloat(lblLastName, 'Opacity', 0);
    TAnimator.AnimateFloat(edtLastName, 'Opacity', 0);

    btnLogin.Text := 'Login';
    Self.Caption := 'Please login';
    edtRepeatPassword.Enabled := False;
    TThread.Synchronize(nil,
      procedure
      begin
        Self.ClientHeight := 113;
      end);
  end;
end;

procedure TLoginView.OnLoginFailed(const Message: string);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      TDialogService.MessageDialog(Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
    end);
end;

procedure TLoginView.OnLoginSuccessful;
begin
  Close;
end;

end.
