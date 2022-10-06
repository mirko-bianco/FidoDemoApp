unit AuthenticationService.Domain.UseCases.Remove.Intf;

interface

uses
  System.SysUtils,

  Fido.Exceptions,
  Fido.Functional;

type
  ERemoveUseCase = class abstract (EFidoException);

  ERemoveUseCaseFailure = class(ERemoveUseCase);

  IRemoveUseCase = interface(IInvokable)
    ['{B77394CE-C3CA-4D69-8C38-3B6ED1319D08}']

    function Run(const UserId: TGuid): Context<Void>;
  end;

implementation

end.

