unit AuthenticationService.Domain.UseCases.RefreshToken.DI.Registration;

interface

uses
  System.Classes,
  System.IniFiles,

  Spring,
  Spring.Container,

  Fido.JWT.Manager.Intf,

  AuthenticationService.Domain.UseCases.GenerateAccessToken.Intf,
  AuthenticationService.Domain.UseCases.GenerateRefreshToken.Intf,
  AuthenticationService.Domain.UseCases.RefreshToken.Intf,
  AuthenticationService.Domain.UseCases.RefreshToken,
  AuthenticationService.Domain.TokensCache.Intf;

procedure DIRegistration(const Container: TContainer; const PublicKeyContent: string);

implementation

procedure DIRegistration(const Container: TContainer; const PublicKeyContent: string);
begin
  Container.RegisterType<IRefreshTokenUseCase>(
    function: IRefreshTokenUseCase
    begin
      Result := TRefreshTokenUseCase.Create(
        Container.Resolve<IJWTManager>,
        Container.Resolve<IGenerateAccessTokenUseCase>,
        Container.Resolve<IGenerateRefreshTokenUseCase>,
        PublicKeyContent,
        Container.Resolve<IServerTokensCache>);
    end
  );
end;

end.

