unit AuthorizationService.Domain.Repositories.UserRole.Intf;

interface

uses
  Fido.Exceptions,
  Fido.Functional,

  AuthorizationService.Domain.Entities.UserRole;

type
  EUserRoleRepository = class(EFidoException);

  IUserRoleRepository = interface(IInvokable)
    ['{B6D8E163-53D0-40F6-9106-0C8A455D7C44}']

    function GetRoleByUserId(const UserId: TGuid): Context<string>;
    function SetRoleByUserId(const UserRole: TUserRole): Context<Void>;
  end;

implementation

end.
