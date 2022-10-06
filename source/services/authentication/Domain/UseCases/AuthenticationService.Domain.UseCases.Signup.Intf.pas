unit AuthenticationService.Domain.UseCases.Signup.Intf;

interface

uses
  System.SysUtils,

  Fido.Exceptions,
  Fido.Functional,

  AuthenticationService.Domain.Entities.User;

type
  ESignupUseCase = class abstract (EFidoException);

  ESignupUseCaseValidation = class(ESignupUseCase);
  ESignupUseCaseFailure = class(ESignupUseCase);

  ISignupUseCase = interface(IInvokable)
    ['{7C6E4432-6F21-4BBA-BA72-59FCA0DCE5AF}']

    function Run(const User: TUser): Context<TGuid>;
  end;

implementation

end.

