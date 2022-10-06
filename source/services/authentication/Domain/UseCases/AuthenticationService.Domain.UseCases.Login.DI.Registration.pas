unit AuthenticationService.Domain.UseCases.Login.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  AuthenticationService.Domain.UseCases.Login.Intf,
  AuthenticationService.Domain.UseCases.Login;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<ILoginUseCase, TLoginUseCase>;
end;

end.
