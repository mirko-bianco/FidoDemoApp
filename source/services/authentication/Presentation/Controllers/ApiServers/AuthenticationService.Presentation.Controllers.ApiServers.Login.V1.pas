unit AuthenticationService.Presentation.Controllers.ApiServers.Login.V1;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Types,
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
    FUseCase: ILoginUseCase;
    function DoLogin(const User: Shared<TUser>): Context<TTokens>;
  public
    constructor Create(const UseCase: ILoginUseCase);

    [Path(rmPost, '/1/login')]
    [ResponseCode(204, 'No content')]
    procedure Execute(const [BodyParam] LoginParams: ILoginParams; out [HeaderParam] Authorization: string; out [HeaderParam(Constants.HEADER_REFRESHTOKEN)] RefreshToken: string);
  end;
  {$M-}

implementation

{ TLoginV1ApiServerController }

constructor TLoginV1ApiServerController.Create(const UseCase: ILoginUseCase);
begin
  inherited Create;

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
  Tokens: TTokens;
begin
  Tokens := &Try<Shared<TUser>>.
    New(TUser.Create(LoginParams.Username, LoginParams.Password)).
    Map<TTokens>(DoLogin).
    Match(function(const E: Exception): Nullable<TTokens>
      begin
        if E is ELoginUseCaseValidation then
          raise EApiServer400.Create(E.Message)
        else if E is ELoginUseCaseFailure then
          raise EApiServer401.Create(E.Message);
      end);
  Authorization := Format('Bearer %s', [Tokens.AccessToken]);
  RefreshToken := Tokens.RefreshToken;
end;

end.
