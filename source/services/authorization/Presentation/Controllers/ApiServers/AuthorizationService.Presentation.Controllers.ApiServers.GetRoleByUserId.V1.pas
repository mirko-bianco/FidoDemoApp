unit AuthorizationService.Presentation.Controllers.ApiServers.GetRoleByUserId.V1;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Types,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Utilities,
  Fido.Http.Types,
  Fido.Api.Server.Exceptions,
  Fido.Api.Server.Resource.Attributes,
  Fido.Api.Server.Consul.Resource.Attributes,

  FidoApp.Constants,

  AuthorizationService.Domain.UseCases.GetRoleByUserId.Intf;

type
  {$M+}
  [BaseUrl(Constants.API_PREFIX)]
  [Consumes(mtJson)]
  [Produces(mtJson)]
  TGetRoleByUserIdV1ApiServerController = class(TObject)
  private
    FGetRoleByUserIdUseCase: IGetRoleByUserIdUseCase;
    function DoGetRole(const Authorization: string): Context<TUserRoleAndPermissions>;
  public
    constructor Create(const GetRoleByUserIdUseCase: IGetRoleByUserIdUseCase);

    [Path(rmGet, '/1/role')]
    [RequestMiddleware('Authenticated')]
    [ResponseMiddleware('ForwardTokens')]
    function Execute(const [HeaderParam] Authorization: string): TUserRoleAndPermissions;
  end;
  {$M-}

implementation

{ TGetRoleByUserIdV1ApiServerController }

constructor TGetRoleByUserIdV1ApiServerController.Create(const GetRoleByUserIdUseCase: IGetRoleByUserIdUseCase);
begin
  inherited Create;

  FGetRoleByUserIdUseCase := Utilities.CheckNotNullAndSet(GetRoleByUserIdUseCase, 'GetRoleByUserIdUseCase');
end;

function TGetRoleByUserIdV1ApiServerController.DoGetRole(const Authorization: string): Context<TUserRoleAndPermissions>;
begin
  Result := FGetRoleByUserIdUseCase.Run(Authorization);
end;

function TGetRoleByUserIdV1ApiServerController.Execute(const Authorization: string): TUserRoleAndPermissions;
begin
  Result := &Try<string>.
    New(Authorization).
    Map<TUserRoleAndPermissions>(DoGetRole).
    Match(function(const E: Exception): Nullable<TUserRoleAndPermissions>
      begin
        if E is EGetRoleByUserIdUseCaseUnauthorized then
          raise EApiServer401.Create(E.Message);
      end);
end;

end.
