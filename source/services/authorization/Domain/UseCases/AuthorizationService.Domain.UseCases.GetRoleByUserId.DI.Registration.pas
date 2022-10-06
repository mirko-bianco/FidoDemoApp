unit AuthorizationService.Domain.UseCases.GetRoleByUserId.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  AuthorizationService.Domain.UseCases.GetRoleByUserId.Intf,
  AuthorizationService.Domain.UseCases.GetRoleByUserId;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IGetRoleByUserIdUseCase, TGetRoleByUserIdUseCase>;
end;

end.

