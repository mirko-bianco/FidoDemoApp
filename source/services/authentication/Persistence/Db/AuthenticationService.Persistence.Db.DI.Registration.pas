unit AuthenticationService.Persistence.Db.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  AuthenticationService.Persistence.Db.Remove.Intf,
  AuthenticationService.Persistence.Db.Login.Intf,
  AuthenticationService.Persistence.Db.ChangeActiveStatus.Intf,
  AuthenticationService.Persistence.Db.Signup.Intf;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Containers.RegisterVirtualStatement<IDeleteUserCommand>(Container);
  Containers.RegisterVirtualQuery<ILoginDbUserRecord, IGetUserByUsernameAndHashedPasswordQuery>(Container);
  Containers.RegisterVirtualStatement<IUpdateActiveStatusCommand>(Container);
  Containers.RegisterVirtualStatement<IInsertUserCommand>(Container);
end;

end.
