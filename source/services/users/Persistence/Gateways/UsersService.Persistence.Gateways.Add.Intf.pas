unit UsersService.Persistence.Gateways.Add.Intf;

interface

uses
  Fido.Functional;

type
  IInsertGateway = interface(IInvokable)
    ['{628C3388-1540-418A-94D3-2821A0F58C7A}']

    function Execute(const Id: string; const FirstName: string; const LastName: string): Context<Integer>;
  end;

implementation

end.
