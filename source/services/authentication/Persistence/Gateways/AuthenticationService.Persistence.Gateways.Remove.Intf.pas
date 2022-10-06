unit AuthenticationService.Persistence.Gateways.Remove.Intf;

interface

uses
  Fido.Functional;

type

  IRemoveGateway = interface(IInvokable)
    ['{2D33E057-67F0-4736-BFF9-9AF67D437677}']

    function Execute(const Id: string): Context<Integer>;
  end;

implementation

end.
