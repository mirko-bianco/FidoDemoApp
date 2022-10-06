unit AuthorizationService.Persistence.Db.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  AuthorizationService.Persistence.Db.GetRoleByUserId.Intf,
  AuthorizationService.Persistence.Db.SetRoleByUserId.Intf;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Containers.RegisterVirtualQuery<IUserRoleRecord, IGetUserRoleByUserIdQuery>(Container);
  Containers.RegisterVirtualStatement<IUpsertUserRoleByUserIdCommand>(Container);
end;

end.
