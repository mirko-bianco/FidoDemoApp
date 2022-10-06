unit FidoApp.Persistence.Gateways.Authentication;

interface

uses
  Fido.Utilities,
  Fido.Functional,

  FidoApp.Persistence.ApiClients.Authentication.V1.Intf,
  FidoApp.Persistence.Gateways.Authentication.Intf;

type
  TAuthenticationV1ApiClientGateway = class(TInterfacedObject, IAuthenticationV1ApiClientGateway)
  private
    FApi: IAuthenticationV1ApiClient;
    FTimeout: Cardinal;

    procedure DoLogin(const LoginParams: TLoginParams);
    procedure DoRefreshToken;
    procedure DoSignup(const SignupParams: TSignupParams);
  public
    constructor Create(const Api: IAuthenticationV1ApiClient; const Timeout: Cardinal = INFINITE);

    function Signup(const SignupParams: TSignupParams): Context<Void>;

    function Login(const LoginParams: TLoginParams): Context<Void>;

    function RefreshToken: Context<Void>;
  end;

implementation

{ TAuthenticationV1ApiClientGateway }

constructor TAuthenticationV1ApiClientGateway.Create(
  const Api: IAuthenticationV1ApiClient;
  const Timeout: Cardinal);
begin
  inherited Create;
  FApi := Utilities.CheckNotNullAndSet(Api, 'Api');
  FTimeout := Timeout;
end;

procedure TAuthenticationV1ApiClientGateway.DoLogin(const LoginParams: TLoginParams);
begin
  FApi.Login(LoginParams);
end;

function TAuthenticationV1ApiClientGateway.Login(const LoginParams: TLoginParams): Context<Void>;
begin
  Result := Context<TLoginParams>.New(LoginParams).MapAsync<Void>(Void.MapProc<TLoginParams>(DoLogin), FTimeout);
end;

procedure TAuthenticationV1ApiClientGateway.DoRefreshToken;
begin
  FApi.RefreshToken;
end;

function TAuthenticationV1ApiClientGateway.RefreshToken: Context<Void>;
begin
  Result := Context<Void>.New(Void.Get).MapAsync<Void>(Void.MapProc(DoRefreshToken), FTimeout);
end;

procedure TAuthenticationV1ApiClientGateway.DoSignup(const SignupParams: TSignupParams);
begin
  FApi.Signup(SignupParams);
end;

function TAuthenticationV1ApiClientGateway.Signup(const SignupParams: TSignupParams): Context<Void>;
begin
  Result := Context<TSignupParams>.New(SignupParams).MapAsync<Void>(Void.MapProc<TSignupParams>(DoSignup), FTimeout);
end;

end.

