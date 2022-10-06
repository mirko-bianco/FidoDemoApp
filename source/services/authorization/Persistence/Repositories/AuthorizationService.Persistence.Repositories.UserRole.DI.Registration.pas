unit AuthorizationService.Persistence.Repositories.UserRole.DI.Registration;

interface

uses
  Spring.Container,

  AuthorizationService.Persistence.Repositories.UserRole,
  AuthorizationService.Domain.Repositories.UserRole.Intf;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IUserRoleRepository, TUserRoleRepository>;
end;

end.
