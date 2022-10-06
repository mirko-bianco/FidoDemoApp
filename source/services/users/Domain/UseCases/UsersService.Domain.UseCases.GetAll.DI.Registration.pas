unit UsersService.Domain.UseCases.GetAll.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  UsersService.Domain.UseCases.GetAll.Intf,
  UsersService.Domain.UseCases.GetAll;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IGetAllUseCase, TGetAllUseCase>;
end;

end.
