unit UsersService.Domain.UseCases.Remove.DI.Registration;

interface

uses
  Spring.Container,

  Fido.Containers,

  UsersService.Domain.UseCases.Remove.Intf,
  UsersService.Domain.UseCases.Remove;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IRemoveUseCase, TRemoveUseCase>;
end;

end.
