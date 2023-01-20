unit AuthorizationService.Presentation.Controllers.ApiServers.SetRoleByUserId.V1;

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

  AuthorizationService.Domain.UseCases.SetRoleByUserId.Intf,
  AuthorizationService.Domain.Entities.UserRole;

type
  {$M+}
  [BaseUrl(Constants.API_PREFIX)]
  [Consumes(mtJson)]
  [Produces(mtJson)]
  TSetRoleByUserIdV1ApiServerController = class(TObject)
  private
    FSetRoleByUserIdUseCase: ISetRoleByUserIdUseCase;

    function SetRole(const UserRole: TUserRole): Context<Void>;
    function DoSetRole(const UserRole: TUserRole): Context<Void>;
  public
    constructor Create(const SetRoleByUserIdUseCase: ISetRoleByUserIdUseCase);

    [Path(rmPatch, '/1/role/{userid}/{role}')]
    [RequestMiddleware('Authenticated')]
    [RequestMiddleware('Authorized', Constants.PERMISSION_CAN_SET_USER_ROLE)]
    [ResponseMiddleware('ForwardTokens')]
    [ResponseCode(204, 'No content')]
    procedure Execute(const [PathParam] UserId: TGuid; const [PathParam] Role: string);
  end;
  {$M-}

implementation

{ TGetRoleByUserIdV1ApiServerController }

constructor TSetRoleByUserIdV1ApiServerController.Create(const SetRoleByUserIdUseCase: ISetRoleByUserIdUseCase);
begin
  inherited Create;

  FSetRoleByUserIdUseCase := Utilities.CheckNotNullAndSet(SetRoleByUserIdUseCase, 'SetRoleByUserIdUseCase');
end;

function TSetRoleByUserIdV1ApiServerController.DoSetRole(const UserRole: TUserRole): Context<Void>;
begin
  Result := FSetRoleByUserIdUseCase.Run(UserRole);
end;

function TSetRoleByUserIdV1ApiServerController.SetRole(const UserRole: TUserRole): Context<Void>;
begin
  Result := &Try<TUserRole>.
    New(UserRole).
    Map<Void>(DoSetRole).
    Match(nil);
end;

procedure TSetRoleByUserIdV1ApiServerController.Execute(
  const UserId: TGuid;
  const Role: string);
begin
  Context<TUserRole>.New(TUserRole.Create(UserId, Role)).Map<Void>(SetRole).Value;
end;

end.
