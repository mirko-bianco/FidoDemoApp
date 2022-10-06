unit AuthorizationService.Domain.UseCases.ConvertToJWT.DI.Registration;

interface

uses
  System.Classes,
  System.IniFiles,

  Spring,
  Spring.Container,

  Fido.JWT.Manager.Intf,

  AuthorizationService.Domain.UseCases.ConvertToJWT.Intf,
  AuthorizationService.Domain.UseCases.ConvertToJWT;

procedure DIRegistration(const Container: TContainer; const PublicKeyContent: string);

implementation

procedure DIRegistration(const Container: TContainer; const PublicKeyContent: string);
begin
  Container.RegisterType<IConvertToJWTUseCase>.DelegateTo(
    function: IConvertToJWTUseCase
    begin
      Result := TConvertToJWTUseCase.Create(
        Container.Resolve<IJWTManager>,
        PublicKeyContent);
    end);
end;

end.
