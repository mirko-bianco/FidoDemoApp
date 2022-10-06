unit UsersService.Persistence.Db.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  UsersService.Persistence.Db.Add.Intf,
  UsersService.Persistence.Db.Remove.Intf,
  UsersService.Persistence.Db.Types,
  UsersService.Persistence.Db.GetAll.Intf,
  UsersService.Persistence.Db.GetCount.Intf;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Containers.RegisterVirtualStatement<IDeleteUserCommand>(Container);
  Containers.RegisterVirtualStatement<IInsertUserCommand>(Container);
  Containers.RegisterVirtualQuery<IUserRecord, IGetAllUsersQuery>(Container);
  Containers.RegisterVirtualStatement<IGetUsersCountQuery>(Container);
end;

end.
