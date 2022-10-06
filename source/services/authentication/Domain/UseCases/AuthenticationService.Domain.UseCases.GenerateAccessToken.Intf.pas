unit AuthenticationService.Domain.UseCases.GenerateAccessToken.Intf;

interface

uses
  Fido.Exceptions,
  Fido.Functional;

type
  EGenerateAccessTokenUseCase = class abstract (EFidoException);

  EGenerateAccessTokenUseCaseFailure = class(EGenerateAccessTokenUseCase);

  IGenerateAccessTokenUseCase = interface(IInvokable)
    ['{1939DADC-D47F-4484-B33C-93280869E387}']

    function Run(const UserId: TGuid): Context<string>;
  end;

implementation

end.

