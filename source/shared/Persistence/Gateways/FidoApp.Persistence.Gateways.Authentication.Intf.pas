unit FidoApp.Persistence.Gateways.Authentication.Intf;

interface

uses
  Fido.Functional,

  FidoApp.Persistence.ApiClients.Authentication.V1.Intf;

type
  IAuthenticationV1ApiClientGateway = interface(IInvokable)
    ['{AD8CF69A-E9F1-4EB0-B9F0-0506613A8A1E}']

    function Signup(const SignupParams: TSignupParams): Context<Void>;

    function Login(const LoginParams: TLoginParams): Context<Void>;

    function RefreshToken: Context<Void>;
  end;

implementation

end.

