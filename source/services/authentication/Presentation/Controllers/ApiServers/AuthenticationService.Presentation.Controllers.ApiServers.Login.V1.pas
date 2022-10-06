unit AuthenticationService.Presentation.Controllers.ApiServers.Login.V1;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Logging,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Types,
  Fido.Logging.Utils,
  Fido.Http.Types,
  Fido.Api.Server.Exceptions,
  Fido.Api.Server.Resource.Attributes,
  Fido.Api.Server.Consul.Resource.Attributes,

  FidoApp.Constants,

  AuthenticationService.Domain.UseCases.Types,
  AuthenticationService.Domain.UseCases.Login.Intf,
  AuthenticationService.Domain.Entities.User;

type
  {$M+}
  ILoginParams = interface(IInvokable)
    ['{3FAE4536-921E-4D34-8E8A-9516AEEEB5A9}']
    function Username: string;
    function Password: string;
  end;

  [BaseUrl(Constants.API_PREFIX)]
  [Consumes(mtJson)]
  [Produces(mtJson)]
  TLoginV1ApiServerController = class(TObject)
  private
    FLogger: ILogger;
    FUseCase: ILoginUseCase;
    function DoLogin(const User: Shared<TUser>): Context<TTokens>;
  public
    constructor Create(const Logger: ILogger; const UseCase: ILoginUseCase);

    [Path(rmPost, '/1/login')]
    procedure Execute(const [BodyParam] LoginParams: ILoginParams; out [HeaderParam] Authorization: string; out [HeaderParam(Constants.HEADER_REFRESHTOKEN)] RefreshToken: string);
  end;
  {$M-}

implementation

{ TLoginV1ApiServerController }

constructor TLoginV1ApiServerController.Create(const Logger: ILogger; const UseCase: ILoginUseCase);
begin
  inherited Create;

  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
  FUseCase := Utilities.CheckNotNullAndSet(UseCase, 'UseCase');
end;

function TLoginV1ApiServerController.DoLogin(const User: Shared<TUser>): Context<TTokens>;
begin
  Result := FUseCase.Run(User);
end;

procedure TLoginV1ApiServerController.Execute(
  const LoginParams: ILoginParams;
  out Authorization: string;
  out RefreshToken: string);
var
  LAuthorization: string;
  LRefreshToken: string;
begin
  Logging.LogDuration(
    FLogger,
    ClassName,
    'Execute',
    procedure
    var
      Tokens: TTokens;
    begin
      Tokens := &Try<Shared<TUser>>.
        New(TUser.Create(LoginParams.Username, LoginParams.Password)).
        Map<TTokens>(DoLogin).
        Match(function(const E: TObject): TTokens
          begin
            if E is ELoginUseCaseValidation then
              raise EApiServer400.Create((E as Exception).Message)
            else if E is ELoginUseCaseFailure then
              raise EApiServer401.Create((E as Exception).Message)
            else
              raise EApiServer500.Create((E as Exception).Message, FLogger, ClassName, 'Execute');
          end);
      LAuthorization := Tokens.AccessToken;
      LRefreshToken := Tokens.RefreshToken;
    end);
  Authorization := Format('Bearer %s', [LAuthorization]);
  RefreshToken := LRefreshToken;
end;

end.
