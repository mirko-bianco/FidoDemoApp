unit AuthenticationService.Domain.UseCases.AddRoleToToken.Intf;

interface

uses
  JOSE.Core.JWT,

  Fido.Exceptions,
  Fido.Functional;

type
  EAddRoleToTokenUseCase = class abstract (EFidoException);

  EAddRoleToTokenUseCaseFailure = class(EAddRoleToTokenUseCase);

  IAddRoleToTokenUseCase = interface(IInvokable)
    ['{92338143-E489-4A33-9405-D16F47D387DE}']

    function Run(const AccessToken: TJWT): Context<Void>;
  end;

implementation

end.

