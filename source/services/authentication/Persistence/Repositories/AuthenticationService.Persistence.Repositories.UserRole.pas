unit AuthenticationService.Persistence.Repositories.UserRole;

interface

uses
  System.SysUtils,

  Spring.Collections,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Retries,
  Fido.Types,
  Fido.DesignPatterns.Retries,
  Fido.JSON.Marshalling,
  Fido.Api.Client.Exception,

  FidoApp.Types,
  FidoApp.Persistence.Gateways.Authorization.Intf,

  AuthenticationService.Domain.Repositories.UserRole.Intf;

type
  TUserRoleRepository = class(TInterfacedObject, IUserRoleRepository)
  private
    FGateway: IAuthorizationV1ApiClientGateway;
    function DoGetRole: Context<IUserRoleAndPermissions>;
  public
    constructor Create(const Gateway: IAuthorizationV1ApiClientGateway);

    function GetByToken: Context<IUserRoleAndPermissions>;
  end;

implementation

{ TAddRoleToTokenRepository }

constructor TUserRoleRepository.Create(const Gateway: IAuthorizationV1ApiClientGateway);
begin
  inherited Create;

  FGateway := Utilities.CheckNotNullAndSet(Gateway, 'Gateway');
end;

function TUserRoleRepository.DoGetRole: Context<IUserRoleAndPermissions>;
begin
  Result := FGateway.GetRole;
end;

function TUserRoleRepository.GetByToken: Context<IUserRoleAndPermissions>;
begin
  Result := Retry.
    Map<IUserRoleAndPermissions>(DoGetRole, Retries.GetRetriesOnExceptionFunc());
end;

end.

