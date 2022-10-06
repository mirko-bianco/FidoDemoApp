unit AuthenticationService.Persistence.Gateways.Signup.Intf;

interface

uses
  Fido.Functional;

type
  ISignupGateway = interface(IInvokable)
    ['{9C80EEAF-043C-4D9D-9109-002BA161EF05}']

    function Execute(const Id: string; const Username: string; const HashedPassword: string): Context<Integer>;
  end;

implementation

end.
