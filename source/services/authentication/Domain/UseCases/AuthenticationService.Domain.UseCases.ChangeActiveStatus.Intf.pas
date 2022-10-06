unit AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf;

interface

uses
  Fido.Exceptions,
  Fido.Functional,

  AuthenticationService.Domain.Entities.UserStatus;

type
  EChangeActiveStatusUseCase = class abstract (EFidoException);

  EChangeActiveStatusUseCaseFailure = class(EChangeActiveStatusUseCase);

  IChangeActiveStatusUseCase = interface(IInvokable)
    ['{B0536C3E-BA1D-4786-9A69-547797B21CAB}']

    function Run(const UserStatus: TUserStatus): Context<Void>;
  end;

implementation

end.

