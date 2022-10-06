unit UsersService.Domain.Repositories.User.Intf;

interface

uses
  Spring,
  Spring.Collections,

  Fido.Exceptions,
  Fido.Functional,

  FidoApp.Types,

  UsersService.Domain.Entities.User;

type
  EUserRepository = class(EFidoException);

  EUserRepositoryValidation = class(EFidoException);

  IUserRepository = interface(IInvokable)
  ['{69E57AB5-B1EA-4D06-AA8F-3520FA310A5C}']

    function Store(const User: TUser): Context<Void>;
    function Remove(const Id: TGuid): Context<Void>;
    function GetAllCount: Context<Integer>;
    function GetAll(const OrderBy: TGetAllUsersOrderBy; const Limit: Integer; const Offset: Integer): Context<IReadOnlyList<TUser>>;
  end;

implementation

end.
