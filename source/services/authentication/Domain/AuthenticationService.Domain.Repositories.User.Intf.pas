unit AuthenticationService.Domain.Repositories.User.Intf;

interface

uses
  Fido.Exceptions,
  Fido.Functional,

  AuthenticationService.Domain.Entities.UserStatus,
  AuthenticationService.Domain.Entities.User;

type
  EUserRepository = class(EFidoException);

  IUserRepository = interface(IInvokable)
  ['{7D0FE663-98C8-4199-8A67-8BF7A64A521E}']

    function UpdateActiveByUserId(const UserStatus: TUserStatus): Context<Void>;
    function Login(const User: TUser): Context<TGuid>;
    function Remove(const Id: TGuid): Context<Void>;
    function Store(const Id: TGuid; const User: TUser): Context<Void>;
  end;

implementation

end.
