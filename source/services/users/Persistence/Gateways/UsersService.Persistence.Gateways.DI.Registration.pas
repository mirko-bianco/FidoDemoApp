unit UsersService.Persistence.Gateways.DI.Registration;

interface

uses
  Spring.Container,

  UsersService.Persistence.Gateways.Add.Intf,
  UsersService.Persistence.Gateways.Add,
  UsersService.Persistence.Gateways.GetAll.Intf,
  UsersService.Persistence.Gateways.GetAll,
  UsersService.Persistence.Gateways.Remove.Intf,
  UsersService.Persistence.Gateways.Remove,
  UsersService.Persistence.Gateways.GetCount.Intf,
  UsersService.Persistence.Gateways.GetCount;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IInsertGateway, TInsertGateway>;
  Container.RegisterType<IGetAllUsersGateway, TGetAllUsersGateway>;
  Container.RegisterType<IGetUsersCountGateway, TGetUsersCountGateway>;
  Container.RegisterType<IDeleteUserGateway, TDeleteUserGateway>;
end;

end.
