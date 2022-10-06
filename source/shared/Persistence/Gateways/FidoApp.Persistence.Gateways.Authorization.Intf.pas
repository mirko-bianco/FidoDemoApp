unit FidoApp.Persistence.Gateways.Authorization.Intf;

interface

uses
  Fido.Functional,

  FidoApp.Types;

type
  IAuthorizationV1ApiClientGateway = interface(IInvokable)
    ['{D80A7893-362A-4CBA-9813-3FDAA86D3DAB}']

    function GetRole: Context<IUserRoleAndPermissions>;
  end;

implementation

end.

