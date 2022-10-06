unit AuthenticationService.Persistence.Repositories.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  AuthenticationService.Persistence.Repositories.User,
  AuthenticationService.Persistence.Repositories.UserRole,
  AuthenticationService.Domain.Repositories.User.Intf,
  AuthenticationService.Domain.Repositories.UserRole.Intf;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IUserRepository, TUserRepository>;
  Container.RegisterType<IUserRoleRepository, TUserRoleRepository>;
end;

end.
