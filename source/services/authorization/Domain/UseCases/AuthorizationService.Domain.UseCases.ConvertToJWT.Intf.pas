unit AuthorizationService.Domain.UseCases.ConvertToJWT.Intf;

interface

uses
  Spring,

  JOSE.Core.JWT,

  Fido.Exceptions,
  Fido.Functional;

type
  EConvertToJWTUseCase = class(EFidoException);
  EConvertToJWTUseCaseValidation = class(EConvertToJWTUseCase);

  IConvertToJWTUseCase = interface(IInvokable)
    ['{EED8DD6F-8696-4334-8A6D-78E7ED01FD85}']

    function Run(const Authorization: string): Context<TJWT>;
  end;

implementation

end.
