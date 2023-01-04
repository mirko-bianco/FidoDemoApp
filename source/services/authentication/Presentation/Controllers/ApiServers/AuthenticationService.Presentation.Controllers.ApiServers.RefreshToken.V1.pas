unit AuthenticationService.Presentation.Controllers.ApiServers.RefreshToken.V1;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.Types,
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
    FUseCase: IRefreshTokenUseCase;

    function DoRefreshToken(const RefreshToken: string): Context<TTokens>;
  public
    constructor Create(const UseCase: IRefreshTokenUseCase);

    [Path(rmGet, '/1/refresh')]
    [ResponseCode(204, 'No content')]
    procedure Execute(const [HeaderParam(Constants.HEADER_REFRESHTOKEN)] RefreshToken: string; out [HeaderParam] Authorization: string; out [HeaderParam(Constants.HEADER_REFRESHTOKEN)] outRefreshToken: string);
  end;
  {$M-}

implementation

{ TRefreshTokenV1ApiServerController }

constructor TRefreshTokenV1ApiServerController.Create(const UseCase: IRefreshTokenUseCase);
begin
  inherited Create;

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
  Tokens: TTokens;
begin
  Tokens := &Try<string>.
    New(RefreshToken).
    Map<TTokens>(DoRefreshToken).
    Match(function(const E: Exception): Nullable<TTokens>
      begin
        if E is ERefreshTokenUseCaseValidation then
          raise EApiServer400.Create(E.Message)
        else if E is ERefreshTokenUseCaseUnhauthorized then
          raise EApiServer401.Create(E.Message);
      end);
  Authorization := Format('Bearer %s', [Tokens.AccessToken]);
  OutRefreshToken := Tokens.RefreshToken;
end;

end.
