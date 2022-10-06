unit UsersService.Domain.UseCases.Add.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  UsersService.Domain.UseCases.Add.Intf,
  UsersService.Domain.UseCases.Add;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IAddUseCase, TAddUseCase>;
end;

end.
