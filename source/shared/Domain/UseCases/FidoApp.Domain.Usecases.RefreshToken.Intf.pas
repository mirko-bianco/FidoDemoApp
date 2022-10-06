unit FidoApp.Domain.Usecases.RefreshToken.Intf;

interface

uses
  Fido.Types,
  Fido.Functional,

  FidoApp.Types;

type
  IRefreshTokenUseCase = interface(IInvokable)
    ['{28BD2C0A-8C79-4FB6-989D-BAFD7635E9E4}']

    function Run: Context<Void>;
  end;

implementation

end.
