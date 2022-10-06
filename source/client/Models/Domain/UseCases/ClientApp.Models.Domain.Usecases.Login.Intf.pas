unit ClientApp.Models.Domain.Usecases.Login.Intf;

interface

uses
  Fido.Functional,

  ClientApp.Models.Domain.Entities.LoginUser;

type
  ILoginUseCase = interface(IInvokable)
    ['{12901158-F99F-4108-AEC5-A2E09B590F04}']

    function Run(const User: TLoginUser): Context<Void>;
  end;

implementation

end.
