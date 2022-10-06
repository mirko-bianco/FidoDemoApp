unit AuthenticationService.Domain.UseCases.Signup.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  AuthenticationService.Domain.UseCases.Signup.Intf,
  AuthenticationService.Domain.UseCases.Signup;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<ISignupUseCase, TSignupUseCase>;
end;

end.
