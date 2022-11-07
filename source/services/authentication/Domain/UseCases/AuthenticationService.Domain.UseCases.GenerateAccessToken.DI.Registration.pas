unit AuthenticationService.Domain.UseCases.GenerateAccessToken.DI.Registration;

interface

uses
  System.Classes,

  Spring,
  Spring.Container,

  Fido.Api.Client.VirtualApi.json,
  Fido.JWT.Manager.Intf,

  FidoApp.Domain.ClientTokensCache.Intf,

  AuthenticationService.Domain.UseCases.AddRoleToToken.Intf,
  AuthenticationService.Domain.UseCases.GenerateAccessToken.Intf,
  AuthenticationService.Domain.UseCases.GenerateAccessToken;

procedure DIRegistration(const Container: TContainer; const PublicKeyContent: string; const PrivateKeyContent: string);

implementation

procedure DIRegistration(const Container: TContainer; const PublicKeyContent: string; const PrivateKeyContent: string);
begin
  Container.RegisterType<IGenerateAccessTokenUseCase>(
    function: IGenerateAccessTokenUseCase
    begin
      Result := TGenerateAccessTokenUseCase.Create(
        Container.Resolve<IJWTManager>,
        Container.Resolve<IAddRoleToTokenUseCase>,
        PrivateKeyContent,
        PublicKeyContent,
        Container.Resolve<IClientTokensCache>);
    end);
end;

end.
