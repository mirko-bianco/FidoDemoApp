unit FidoApp.Domain.Repositories.Authentication.Intf;

interface

uses
  Fido.Functional;

type
  IAuthenticationRepository = interface(IInvokable)
    ['{8FFC6726-C4F4-485C-82A8-30D90734EB6D}']

    function RefreshToken: Context<Void>;
  end;

implementation

end.
