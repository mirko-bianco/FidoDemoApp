unit FidoApp.Persistence.Gateways.Authorization;

interface

uses
  Fido.Utilities,
  Fido.Functional,

  FidoApp.Types,
  FidoApp.Persistence.ApiClients.Authorization.V1.Intf,
  FidoApp.Persistence.Gateways.Authorization.Intf;

type
  TAuthorizationV1ApiClientGateway = class(TInterfacedObject, IAuthorizationV1ApiClientGateway)
  private
    FApi: IAuthorizationV1ApiClient;
    FTimeout: Cardinal;

    function DoGetRoles: IUserRoleAndPermissions;
  public
    constructor Create(const Api: IAuthorizationV1ApiClient; const Timeout: Cardinal = INFINITE);

    function GetRole: Context<IUserRoleAndPermissions>;
  end;

implementation

{ TAuthorizationV1ApiClientGateway }

constructor TAuthorizationV1ApiClientGateway.Create(
  const Api: IAuthorizationV1ApiClient;
  const Timeout: Cardinal);
begin
  inherited Create;
  FApi := Utilities.CheckNotNullAndSet(Api, 'Api');
  FTimeout := Timeout;
end;

function TAuthorizationV1ApiClientGateway.DoGetRoles: IUserRoleAndPermissions;
begin
  Result := FApi.GetRole;
end;

function TAuthorizationV1ApiClientGateway.GetRole: Context<IUserRoleAndPermissions>;
begin
  Result := Context<Void>.New(Void.Get).MapAsync<IUserRoleAndPermissions>(Void.MapFunc<IUserRoleAndPermissions>(DoGetRoles), FTimeout);
end;

end.
