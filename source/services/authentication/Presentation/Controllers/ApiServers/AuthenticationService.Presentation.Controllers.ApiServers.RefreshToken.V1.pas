unit AuthenticationService.Presentation.Controllers.ApiServers.RefreshToken.V1;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Logging,

  Fido.Utilities,
  Fido.Types,
  Fido.Logging.Utils,
  Fido.Http.Types,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Api.Server.Exceptions,
  Fido.Api.Server.Resource.Attributes,
  Fido.Api.Server.Consul.Resource.Attributes,

  FidoApp.Constants,

  AuthenticationService.Domain.UseCases.Types,
  AuthenticationService.Domain.UseCases.RefreshToken.Intf;

type
  {$M+}
  [BaseUrl(Constants.API_PREFIX)]
  [Consumes(mtJson)]
  [Produces(mtJson)]
  TRefreshTokenV1ApiServerController = class(TObject)
  private
    FLogger: ILogger;
    FUseCase: IRefreshTokenUseCase;

    function DoRefreshToken(const RefreshToken: string): Context<TTokens>;
  public
    constructor Create(const Logger: ILogger; const UseCase: IRefreshTokenUseCase);

    [Path(rmGet, '/1/refresh')]
    procedure Execute(const [HeaderParam(Constants.HEADER_REFRESHTOKEN)] RefreshToken: string; out [HeaderParam] Authorization: string; out [HeaderParam(Constants.HEADER_REFRESHTOKEN)] outRefreshToken: string);
  end;
  {$M-}

implementation

{ TRefreshTokenV1ApiServerController }

constructor TRefreshTokenV1ApiServerController.Create(
  const Logger: ILogger;
  const UseCase: IRefreshTokenUseCase);
begin
  inherited Create;

  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
  FUseCase := Utilities.CheckNotNullAndSet(UseCase, 'UseCase');
end;

function TRefreshTokenV1ApiServerController.DoRefreshToken(const RefreshToken: string): Context<TTokens>;
begin
  Result := FUseCase.Run(RefreshToken);
end;

procedure TRefreshTokenV1ApiServerController.Execute(
  const RefreshToken: string;
  out Authorization: string;
  out outRefreshToken: string);
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
      Tokens := &Try<string>.
        New(RefreshToken).
        Map<TTokens>(DoRefreshToken).
        Match(function(const E: TObject): TTokens
          begin
            if E is ERefreshTokenUseCaseValidation then
              raise EApiServer400.Create((E as Exception).Message)
            else if E is ERefreshTokenUseCaseUnhauthorized then
              raise EApiServer401.Create((E as Exception).Message)
            else
              raise EApiServer500.Create((E as Exception).Message, FLogger, ClassName, 'Execute');
          end);
      LAuthorization := Tokens.AccessToken;
      LRefreshToken := Tokens.RefreshToken;
    end);
  Authorization := Format('Bearer %s', [LAuthorization]);
  OutRefreshToken := LRefreshToken;
end;

end.
