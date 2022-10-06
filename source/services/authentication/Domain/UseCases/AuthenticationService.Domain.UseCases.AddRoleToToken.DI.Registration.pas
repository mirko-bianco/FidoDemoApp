unit AuthenticationService.Domain.UseCases.AddRoleToToken.DI.Registration;

interface

uses
  System.Classes,
  
  Spring.Container,

  Fido.Api.Client.VirtualApi.json,
  Fido.JWT.Manager.Intf,

  AuthenticationService.Domain.UseCases.AddRoleToToken.Intf,
  AuthenticationService.Domain.UseCases.AddRoleToToken,
  AuthenticationService.Domain.Repositories.UserRole.Intf;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
begin
  Container.RegisterType<IAddRoleToTokenUseCase>.DelegateTo(
    function: IAddRoleToTokenUseCase
    begin
      Result := TAddRoleToTokenUseCase.Create(
        function: IUserRoleRepository
        begin
          Result := Container.Resolve<IUserRoleRepository>;
        end);
    end);
end;

end.
