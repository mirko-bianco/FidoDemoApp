unit AuthenticationService.Domain.UseCases.RefreshToken.Intf;

interface

uses
  Fido.Exceptions,
  Fido.Functional,

  AuthenticationService.Domain.UseCases.Types;

type
  ERefreshTokenUseCase = class(EFidoException);
  ERefreshTokenUseCaseValidation = class(ERefreshTokenUseCase);
  ERefreshTokenUseCaseUnhauthorized = class(ERefreshTokenUseCase);

  IRefreshTokenUseCase = interface(IInvokable)
    ['{72571D96-A218-403F-8680-876AF57E294C}']

    function Run(const RefreshToken: string): Context<TTokens>;
  end;

implementation

end.
