unit ClientApp.Models.Domain.Usecases.Signup.Intf;

interface

uses
  Fido.Types,
  Fido.Functional,

  FidoApp.Types,

  ClientApp.Models.Domain.Entities.SignupUser;

type
  ISignupUseCase = interface(IInvokable)
    ['{8F5DB6D3-7029-46D0-9202-74EB9E3AF5E2}']

    function Run(const User: TSignupUser): Context<Void>;
  end;

implementation

end.
