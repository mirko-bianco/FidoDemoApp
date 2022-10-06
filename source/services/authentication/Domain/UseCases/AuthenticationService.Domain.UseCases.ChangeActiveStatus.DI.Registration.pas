unit AuthenticationService.Domain.UseCases.ChangeActiveStatus.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf,
  AuthenticationService.Domain.UseCases.ChangeActiveStatus;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IChangeActiveStatusUseCase, TChangeActiveStatusUseCase>;
end;

end.

