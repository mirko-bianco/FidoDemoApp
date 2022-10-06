unit AuthorizationService.Persistence.Gateways.GetRoleByUserId.Intf;

interface

uses
  Fido.Functional,

  AuthorizationService.Domain.Entities.UserRole,
  AuthorizationService.Persistence.Db.GetRoleByUserId.Intf;

type

  IGetUserRoleByUserIdGateway = interface(IInvokable)
    ['{B2BBA6C5-0B40-4D36-B9AD-706C9EE801F4}']

    function Open(const UserId: string): Context<TUserRole>;
  end;

implementation

end.
