unit UsersService.Persistence.Gateways.Remove.Intf;

interface

uses
  Fido.Functional;

type
  IDeleteUserGateway = interface(IInvokable)
    ['{ABCD920F-53DD-4631-A11F-83E1BD93E3F3}']

    function Execute(const Id: string): Context<Integer>;
  end;

implementation

end.
