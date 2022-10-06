unit AuthenticationService.Persistence.Gateways.Login.Intf;

interface

uses
  Fido.Functional,

  AuthenticationService.Domain.Entities.User,
  AuthenticationService.Persistence.Db.Login.Intf;

type
  ILoginGateway = interface(IInvokable)
    ['{9D2B3960-284B-4077-8AA5-512B4FA54E58}']

    function Get(const Username: string; const HashedPassword: string): Context<TGuid>;
  end;

implementation

end.
