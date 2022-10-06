unit ClientApp.Models.Persistence.Repositories.Authentication;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Functional.Retries,
  Fido.Types,
  Fido.DesignPatterns.Retries,

  FidoApp.Types,
  FidoApp.Persistence.ApiClients.Authentication.V1.Intf,
  FidoApp.Persistence.Gateways.Authentication.Intf,

  ClientApp.Models.Domain.Repositories.Authentication.Intf,
  ClientApp.Models.Domain.Entities.LoginUser,
  ClientApp.Models.Domain.Entities.SignupUser;

type
  TAuthenticationRepository = class(TInterfacedObject, IAuthenticationRepository)
  private
    FGateway: IAuthenticationV1ApiClientGateway;

    function MapLoginDto(const User: TLoginUser): TLoginParams;
    function MapSignupDto(const User: TSignupUser): TSignupParams;
    function DoSignup(const SignupParams: TSignupParams): Context<Void>;
    function DoLogin(const LoginParams: TLoginParams): Context<Void>;
    procedure DoValidateLoginResult(const Succeeded: Boolean);
    procedure DoValidateSignupResult(const Succeeded: Boolean);
  public
    constructor Create(const Gateway: IAuthenticationV1ApiClientGateway);

    function Login(const User: TLoginUser): Context<Void>;
    function Signup(const User: TSignupUser): Context<Void>;
  end;

implementation

{ TAuthenticationRepository }

constructor TAuthenticationRepository.Create(const Gateway: IAuthenticationV1ApiClientGateway);
begin
  inherited Create;

  FGateway := Utilities.CheckNotNullAndSet(Gateway, 'Gateway');
end;

function TAuthenticationRepository.MapLoginDto(const User: TLoginUser): TLoginParams;
begin
  Result := TLoginParams.Create(User.Username, User.Password);
end;

function TAuthenticationRepository.DoLogin(const LoginParams: TLoginParams): Context<Void>;
begin
  Result := FGateway.Login(LoginParams);
end;

procedure TAuthenticationRepository.DoValidateLoginResult(const Succeeded: Boolean);
begin
  if not Succeeded then
    raise EAuthenticationRepository.Create('Could not login at this time.')
end;

function TAuthenticationRepository.Login(const User: TLoginUser): Context<Void>;
begin
  Result := &Try<Void>.
    New(Retry<TLoginParams>.
      New(Context<TLoginUser>.
        New(User).
        Map<TLoginParams>(MapLoginDto)).
      Map<Void>(DoLogin, Retries.GetRetriesOnExceptionFunc())).
    Match.
    Map<Void>(Void.MapProc<Boolean>(DoValidateLoginResult));
end;

function TAuthenticationRepository.MapSignupDto(const User: TSignupUser): TSignupParams;
begin
  Result := TSignupParams.Create(User.Username, User.Password, User.FirstName, User.LastName)
end;

function TAuthenticationRepository.DoSignup(const SignupParams: TSignupParams): Context<Void>;
begin
  Result := FGateway.Signup(SignupParams);
end;

procedure TAuthenticationRepository.DoValidateSignupResult(const Succeeded: Boolean);
begin
  if not Succeeded then
    raise EAuthenticationRepository.Create('Could not signup at this time.')
end;

function TAuthenticationRepository.Signup(const User: TSignupUser): Context<Void>;
begin
  Result := &Try<Void>.
    New(Retry<TSignupParams>.New(
      Context<TSignupUser>.
      New(User).
      Map<TSignupParams>(MapSignupDto)).
    Map<Void>(DoSignup, Retries.GetRetriesOnExceptionFunc())).
    Match.
    Map<Void>(Void.MapProc<Boolean>(DoValidateSignupResult));
end;

end.
