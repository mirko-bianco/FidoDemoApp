unit UsersService.Persistence.Gateways.GetCount.Intf;

interface

uses
  Fido.Functional;

type
  IGetUsersCountGateway = interface(IInvokable)
    ['{34633000-93F1-4A78-930F-A7BB36413350}']

    function Open: Context<Integer>;
  end;

implementation

end.
