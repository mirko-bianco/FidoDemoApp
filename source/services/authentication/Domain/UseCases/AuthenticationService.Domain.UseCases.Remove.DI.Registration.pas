unit AuthenticationService.Domain.UseCases.Remove.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  AuthenticationService.Domain.UseCases.Remove.Intf,
  AuthenticationService.Domain.UseCases.Remove;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IRemoveUseCase, TRemoveUseCase>;
end;

end.
