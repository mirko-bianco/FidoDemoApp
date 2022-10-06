unit AuthenticationService.Domain.UseCases.Login.Intf;

interface

uses
  Fido.Exceptions,
  Fido.Functional,

  AuthenticationService.Domain.UseCases.Types,
  AuthenticationService.Domain.Entities.User;

type
  ELoginUseCase = class abstract (EFidoException);

  ELoginUseCaseValidation = class(ELoginUseCase);
  ELoginUseCaseFailure = class(ELoginUseCase);

  ILoginUseCase = interface(IInvokable)
    ['{7C6E4432-6F21-4BBA-BA72-59FCA0DCE5AF}']

    function Run(const User: TUser): Context<TTokens>;
  end;

implementation

end.

