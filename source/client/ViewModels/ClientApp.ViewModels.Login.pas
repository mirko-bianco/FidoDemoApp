unit ClientApp.ViewModels.Login;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Threading,

  Spring,

  Fido.Types,
  Fido.Utilities,
  Fido.DesignPatterns.Observable.Intf,
  Fido.DesignPatterns.Observable.Delegated,
  Fido.Api.Client.Exception,
  Fido.JSON.Marshalling,
  Fido.EventsDriven.Publisher.Intf,
  Fido.Functional,
  Fido.Functional.Tries,

  FidoApp.Types,
  FidoApp.Messages,
  FidoApp.Domain.ClientTokensCache.Intf,

  ClientApp.Types,
  ClientApp.Messages,
  ClientApp.ViewModels.Login.Intf,
  ClientApp.Models.Domain.UseCases.Login.Intf,
  ClientApp.Models.Domain.UseCases.Signup.Intf,
  ClientApp.Models.Domain.Entities.LoginUser,
  ClientApp.Models.Domain.Entities.SignupUser;

type
  TLoginViewModel = class(TDelegatedObservable, ILoginViewModel)
  private
    FPublisher: IEventsDrivenPublisher;
    FLoginUseCase: ILoginUseCase;
    FSignupUseCase: ISignupUseCase;
    FAction: TLoginViewAction;
    FLoginUser: TLoginUser;
    FSignupUser: TSignupUser;

    procedure ChangeBusyStatus(const Value: Boolean);
    procedure ChangeTokens;
    procedure NotifyFailedLogin(const Message: string);
    function DoLogin(const LoginUser: TLoginUser): Context<Void>;
    function DoSignup(const SignupUser: TSignupUser): Context<Void>;
  public
    constructor Create(const Publisher: IEventsDrivenPublisher; const LoginUseCase: ILoginUseCase; const SignupUseCase: ISignupUseCase);

    procedure SwitchAction;
    function Username: string;
    procedure SetUsername(const Value: string);
    function Password: string;
    procedure SetPassword(const Value: string);
    function RepeatedPassword: string;
    procedure SetRepeatedPassword(const Value: string);
    function FirstName: string;
    procedure SetFirstName(const Value: string);
    function LastName: string;
    procedure SetLastName(const Value: string);

    function RunTask: Context<Void>;
    procedure Run;

    procedure Close;
  end;

implementation

{ TLoginModelView }

procedure TLoginViewModel.ChangeBusyStatus(const Value: Boolean);
begin
  FPublisher.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [Value]).Value;
end;

procedure TLoginViewModel.ChangeTokens;
begin
  FPublisher.Trigger('LoginViewModel', TOKEN_CHANGED_MESSAGE, []).Value;
end;

procedure TLoginViewModel.Close;
begin
  FPublisher.Trigger('LoginViewModel', VIEW_CLOSED_MESSAGE, []).Value;
end;

procedure TLoginViewModel.NotifyFailedLogin(const Message: string);
begin
  FPublisher.Trigger('LoginViewModel', LOGIN_FAILED_MESSAGE, [Message]).Value;
end;

constructor TLoginViewModel.Create(
  const Publisher: IEventsDrivenPublisher;
  const LoginUseCase: ILoginUseCase;
  const SignupUseCase: ISignupUseCase);
begin
  inherited Create(nil);
  FPublisher := Utilities.CheckNotNullAndSet(Publisher, 'Publisher');
  FLoginUseCase := Utilities.CheckNotNullAndSet(LoginUseCase, 'LoginUseCase');
  FSignupUseCase := Utilities.CheckNotNullAndSet(SignupUseCase, 'SignupUseCase');
  FAction := TLoginViewAction.Login;
end;

function TLoginViewModel.FirstName: string;
begin
  Result := FSignupUser.FirstName;
end;

function TLoginViewModel.LastName: string;
begin
  Result := FSignupUser.LastName;
end;

procedure TLoginViewModel.Run;
begin
  RunTask.Value;
end;

function TLoginViewModel.DoLogin(const LoginUser: TLoginUser): Context<Void>;
begin
  Result := FLoginUseCase.Run(LoginUser).Map<Void>(Void.MapProc(ChangeTokens));
end;

function TLoginViewModel.DoSignup(const SignupUser: TSignupUser): Context<Void>;
begin
  Result := FSignupUseCase.Run(SignupUser).Map<Void>(Void.MapProc(SwitchAction));
end;

function TLoginViewModel.RunTask: Context<Void>;
var
  LoginUser: TLoginUser;
  SignupUser: TSignupUser;
begin
  LoginUser := FLoginUser;
  SignupUser := FSignupUser;

  if FAction = TLoginViewAction.Login then
  begin
    Context<Boolean>.
      New(True).
      Map<Void>(Void.MapProc<Boolean>(ChangeBusyStatus)).Value;
    Result := &Try<TLoginUser>.
      New(LoginUser).
      Map<Void>(DoLogin).
      Match(function(const E: TObject): Void
        begin
          if E.InheritsFrom(EFidoClientApiException) then
            NotifyFailedLogin(Format('%d: %s', [(E as EFidoClientApiException).ErrorCode, (E as EFidoClientApiException).ErrorMessage]));
        end,
        procedure
        begin
          Context<Boolean>.New(False).Map<Void>(Void.MapProc<Boolean>(ChangeBusyStatus)).Value;
        end);
  end
  else
  begin
    Context<Boolean>.
      New(True).
      Map<Void>(Void.MapProc<Boolean>(ChangeBusyStatus)).Value;
    Result := &Try<TSignupUser>.
      New(SignupUser).
      Map<Void>(DoSignup).
      Match(function(const E: TObject): Void
        begin
          if E.InheritsFrom(ESignupUserValidation) then
            NotifyFailedLogin((E as Exception).Message)
          else
            NotifyFailedLogin(Format('%d: %s', [-1, 'Could not signup at this time']));
        end,
        procedure
        begin
          Context<Boolean>.New(False).Map<Void>(Void.MapProc<Boolean>(ChangeBusyStatus)).Value;
        end);
  end;
end;

function TLoginViewModel.Password: string;
begin
  Result := FLoginUser.Password;
end;

function TLoginViewModel.RepeatedPassword: string;
begin
  Result := FSignupUser.RepeatedPassword;
end;

procedure TLoginViewModel.SwitchAction;
begin
  if FAction = TLoginViewAction.Login then
    FAction := TLoginViewAction.Signup
  else
    FAction := TLoginViewAction.Login;

  SetUsername('');
  SetPassword('');
  SetRepeatedPassword('');
  SetFirstName('');
  SetLastName('');
  FPublisher.Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(FAction)]).Value;
end;

procedure TLoginViewModel.SetFirstName(const Value: string);
begin
  if FSignupUser.FirstName.Equals(Value) then
    Exit;

  FSignupUser.FirstName := Value;
end;

procedure TLoginViewModel.SetLastName(const Value: string);
begin
  if FSignupUser.LastName.Equals(Value) then
    Exit;

  FSignupUser.LastName := Value;
end;

procedure TLoginViewModel.SetPassword(const Value: string);
begin
  if FSignupUser.Password.Equals(Value) then
    Exit;

  FSignupUser.Password := Value;
  FLoginUser.Password := Value;
end;

procedure TLoginViewModel.SetRepeatedPassword(const Value: string);
begin
  if FSignupUser.RepeatedPassword.Equals(Value) then
    Exit;

  FSignupUser.RepeatedPassword := Value;
end;

procedure TLoginViewModel.SetUsername(const Value: string);
begin
  if FSignupUser.Username.Equals(Value) then
    Exit;

  FSignupUser.Username := Value;
  FLoginUser.Username := Value;
end;

function TLoginViewModel.Username: string;
begin
  Result := FSignupUser.Username;
end;

end.
