unit UsersService.Persistence.Gateways.GetAll.Intf;

interface

uses
  Generics.Collections,

  Spring,
  Spring.Collections,

  Fido.Exceptions,
  Fido.Functional,

  UsersService.Domain.Entities.User,
  UsersService.Persistence.Db.Types;

type
  EGetAllUsersGateway = class(EFidoException);

  IGetAllUsersGateway = interface(IInvokable)
    ['{D291A1BC-CE51-4038-BBB5-5BE53D931B14}']

    function Open(const OrderBy: string; const Limit: Integer; const Offset: Integer): Context<IReadOnlyList<TUser>>;
  end;

implementation

end.
