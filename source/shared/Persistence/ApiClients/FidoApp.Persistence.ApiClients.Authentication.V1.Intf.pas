unit FidoApp.Persistence.ApiClients.Authentication.V1.Intf;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Types,
  Fido.Http.Types,
  Fido.Api.Client.VirtualApi.Attributes,
  Fido.Api.Client.VirtualApi.Intf,

  FidoApp.Constants,
  FidoApp.Types,
  FidoApp.Persistence.ApiClients.Configuration.Tokens;

type
  {$M+}
  IAuthenticationV1ApiClientConfiguration = interface(ITokensAwareClientVirtualApiConfiguration)
    ['{C7CF8528-7A32-42B8-BE0D-8AE876B353DD}']
  end;

  TAuthenticationV1ApiClientConfiguration = class(TTokensAwareClientVirtualApiConfiguration, IAuthenticationV1ApiClientConfiguration)
  end;

  TLoginParams = record
  private
    FUsername: string;
    FPassword: string;
  public
    constructor Create(const Username: string; const Password: string);

    function Username: string;
    function Password: string;
  end;

  TSignupParams = record
  private
    FUsername: string;
    FPassword: string;
    FFirstName: string;
    FLastName: string;
  public
    constructor Create(const Username: string; const Password: string; const FirstName: string; const LastName: string);

    function Username: string;
    function Password: string;
    function FirstName: string;
    function LastName: string;
  end;

  IAuthenticationV1ApiClient = interface(IClientVirtualApi)
    ['{F87F13D6-1A5C-4295-997A-A002FB1C927F}']

    [Endpoint(rmPost, '/signup')]
    [RequestParam('SignupParams')]
    function Signup(const SignupParams: TSignupParams): TGuid;

    [Endpoint(rmPost, '/login')]
    [RequestParam('LoginParams')]
    [HeaderParam('RefreshToken', Constants.HEADER_REFRESHTOKEN)]
    [HeaderParam(Constants.HEADER_AUTHORIZATION)]
    procedure Login(const LoginParams: TLoginParams);

    [Endpoint(rmGet, '/refresh')]
    [HeaderParam('RefreshToken', Constants.HEADER_REFRESHTOKEN)]
    [HeaderParam(Constants.HEADER_AUTHORIZATION)]
    procedure RefreshToken;
  end;
  {$M-}

implementation

{ TLoginParams }

constructor TLoginParams.Create(
  const Username: string;
  const Password: string);
begin
  FUsername := Username;
  FPassword := Password;
end;

function TLoginParams.Password: string;
begin
  Result := FPassword;
end;

function TLoginParams.Username: string;
begin
  Result := FUsername;
end;

{ TSignupParams }

constructor TSignupParams.Create(
  const Username: string;
  const Password: string;
  const FirstName: string;
  const LastName: string);
begin
  FUsername := Username;
  FPassword := Password;
  FFirstName := FirstName;
  FLastName := LastName;
end;

function TSignupParams.FirstName: string;
begin
  Result := FFirstName;
end;

function TSignupParams.LastName: string;
begin
  Result := FLastName;
end;

function TSignupParams.Password: string;
begin
  Result := FPassword;
end;

function TSignupParams.Username: string;
begin
  Result := FUsername;
end;

end.

