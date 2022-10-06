unit AuthorizationService.Domain.UseCases.SetRoleByUserId.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  AuthorizationService.Domain.UseCases.SetRoleByUserId.Intf,
  AuthorizationService.Domain.UseCases.SetRoleByUserId;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<ISetRoleByUserIdUseCase, TSetRoleByUserIdUseCase>;
end;

end.
