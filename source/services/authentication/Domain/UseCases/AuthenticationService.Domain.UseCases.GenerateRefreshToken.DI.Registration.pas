unit AuthenticationService.Domain.UseCases.GenerateRefreshToken.DI.Registration;

interface

uses
  System.Classes,
  System.IniFiles,

  Spring,
  Spring.Container,

  Fido.Api.Client.VirtualApi.json,
  Fido.JWT.Manager.Intf,

  AuthenticationService.Domain.UseCases.GenerateRefreshToken.Intf,
  AuthenticationService.Domain.UseCases.GenerateRefreshToken;

procedure DIRegistration(const Container: TContainer; const PublicKeyContent: string; const PrivateKeyContent: string);

implementation

procedure DIRegistration(const Container: TContainer; const PublicKeyContent: string; const PrivateKeyContent: string);
begin
  Container.RegisterType<IGenerateRefreshTokenUseCase>.DelegateTo(
    function: IGenerateRefreshTokenUseCase
    begin
      Result := TGenerateRefreshTokenUseCase.Create(
        Container.Resolve<IJWTManager>,
        PrivateKeyContent,
        PublicKeyContent);
    end);
end;

end.
