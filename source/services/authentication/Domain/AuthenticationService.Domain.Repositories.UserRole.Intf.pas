unit AuthenticationService.Domain.Repositories.UserRole.Intf;

interface

uses
  Fido.Functional,
  Fido.Exceptions,
  Fido.Types,

  FidoApp.Types;

type
  IUserRoleRepository = interface(IInvokable)
  ['{309F0242-D213-47C3-8EF7-02FF2680618D}']

    function GetByToken: Context<IUserRoleAndPermissions>;
  end;

implementation

end.
