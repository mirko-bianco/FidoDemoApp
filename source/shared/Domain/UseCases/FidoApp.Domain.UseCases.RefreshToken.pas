unit FidoApp.Domain.UseCases.RefreshToken;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.Types,
  Fido.Functional,
  Fido.Functional.Retries,

  FidoApp.Types,
  FidoApp.Domain.Usecases.RefreshToken.Intf,
  FidoApp.Domain.Repositories.Authentication.Intf;

type
  TRefreshTokenUseCase = class(TInterfacedObject, IRefreshTokenUseCase)
  private
    FRepository: IAuthenticationRepository;
  public
    constructor Create(const Repository: IAuthenticationRepository);

    function Run: Context<Void>;
  end;

implementation

{ TRefreshTokenUseCase }

constructor TRefreshTokenUseCase.Create(const Repository: IAuthenticationRepository);
begin
  inherited Create;
  FRepository := Utilities.CheckNotNullAndSet(Repository, 'Repository');
end;

function TRefreshTokenUseCase.Run: Context<Void>;
begin
  Result := FRepository.RefreshToken;
end;

end.
