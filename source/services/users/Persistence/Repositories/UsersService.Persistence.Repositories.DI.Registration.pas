unit UsersService.Persistence.Repositories.DI.Registration;

interface

uses
  Spring.Container,

  UsersService.Domain.Repositories.User.Intf,
  UsersService.Persistence.Repositories.User;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IUserRepository, TUserRepository>;
end;

end.
