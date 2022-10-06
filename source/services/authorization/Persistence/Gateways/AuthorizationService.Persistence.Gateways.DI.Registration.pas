unit AuthorizationService.Persistence.Gateways.DI.Registration;

interface

uses
  Spring.Container,

  AuthorizationService.Persistence.Gateways.GetRoleByUserId.Intf,
  AuthorizationService.Persistence.Gateways.GetRoleByUserId,
  AuthorizationService.Persistence.Gateways.SetRoleByUserId.Intf,
  AuthorizationService.Persistence.Gateways.SetRoleByUserId;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IGetUserRoleByUserIdGateway, TGetUserRoleByUserIdGateway>;
  Container.RegisterType<IUpsertUserRoleByUserIdGateway, TUpsertUserRoleByUserIdGateway>;
end;

end.
