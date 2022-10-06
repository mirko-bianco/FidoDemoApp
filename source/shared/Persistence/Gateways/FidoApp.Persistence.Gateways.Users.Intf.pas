unit FidoApp.Persistence.Gateways.Users.Intf;

interface

uses
  Fido.Functional,

  FidoApp.Types;

type
  IUsersV1ApiClientGateway = interface(IInvokable)
    ['{C0E613B5-D004-49DE-BE10-A47CA6556850}']

    function GetAll(const OrderBy: TGetAllUsersOrderBy; const Page: Integer; const Limit: Integer): Context<IGetAllUsersV1Result>;
  end;

implementation

end.

