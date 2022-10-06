unit UsersService.Domain.UseCases.Add.Intf;

interface

uses
  System.SysUtils,

  Fido.Exceptions,
  Fido.Functional,

  UsersService.Domain.Entities.User;

type
  EAddUseCase = class abstract (EFidoException);

  EAddUseCaseValidation = class(EAddUseCase);
  EAddUseCaseFailure = class(EAddUseCase);

  IAddUseCase = interface(IInvokable)
    ['{7C6E4432-6F21-4BBA-BA72-59FCA0DCE5AF}']

    function Run(const User: TUser): Context<Void>;
  end;

implementation

end.

