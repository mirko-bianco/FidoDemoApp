unit AuthenticationService.Domain.UseCases.GenerateRefreshToken.Intf;

interface

uses
  Fido.Exceptions,
  Fido.Functional;

type
  EGenerateRefreshTokenUseCase = class abstract (EFidoException);

  EGenerateRefreshTokenUseCaseFailure = class(EGenerateRefreshTokenUseCase);

  IGenerateRefreshTokenUseCase = interface(IInvokable)
    ['{3F036697-34E5-487D-A6AE-70FD983D22A7}']

    function Run(const UserId: TGuid): Context<string>;
  end;

implementation

end.

