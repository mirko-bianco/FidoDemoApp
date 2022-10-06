unit AuthorizationService.Persistence.Gateways.SetRoleByUserId.Intf;

interface

uses
  Fido.Functional,

  AuthorizationService.Domain.Entities.UserRole;

type
  IUpsertUserRoleByUserIdGateway = interface(IInvokable)
    ['{818E4D54-2347-4C3D-A73D-4BFD2778A8E4}']

    function Exec(const UserRole: TUserRole): Context<Integer>;
  end;

implementation

end.
