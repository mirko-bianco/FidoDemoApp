unit ClientApp.Models.Domain.Repositories.Authentication.Intf;

interface

uses
  Fido.Functional,
  Fido.Exceptions,

  ClientApp.Models.Domain.Entities.LoginUser,
  ClientApp.Models.Domain.Entities.SignupUser;

type
  EAuthenticationRepository = class(EFidoException);

  IAuthenticationRepository = interface(IInvokable)
    ['{33104AE1-FF78-4459-93B7-B4CE97E72C97}']

    function Login(const User: TLoginUser): Context<Void>;
    function Signup(const User: TSignupUser): Context<Void>;
  end;

implementation

end.
