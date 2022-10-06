unit AuthenticationService.Persistence.Gateways.DI.Registration;

interface

uses
  Spring.Container,

  AuthenticationService.Persistence.Gateways.Remove.Intf,
  AuthenticationService.Persistence.Gateways.Remove,
  AuthenticationService.Persistence.Gateways.Login.Intf,
  AuthenticationService.Persistence.Gateways.Login,
  AuthenticationService.Persistence.Gateways.ChangeActiveStatus.Intf,
  AuthenticationService.Persistence.Gateways.ChangeActiveStatus,
  AuthenticationService.Persistence.Gateways.Signup.Intf,
  AuthenticationService.Persistence.Gateways.Signup;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IChangeActiveStatusGateway, TChangeActiveStatusGateway>;
  Container.RegisterType<ILoginGateway, TLoginGateway>;
  Container.RegisterType<IRemoveGateway, TRemoveGateway>;
  Container.RegisterType<ISignupGateway, TSignupGateway>;
end;

end.
