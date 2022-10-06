unit AuthenticationService.Domain.UseCases.GenerateRefreshToken;

interface

uses
  System.SysUtils,
  System.JSON,

  JOSE.Core.JWA,
  JOSE.Core.JWT,

  Spring,

  Fido.Exceptions,
  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Types,
  Fido.JWT.Manager.Intf,

  FidoApp.Constants,
  FidoApp.Types,

  AuthenticationService.Domain.UseCases.GenerateRefreshToken.Intf;

type
  TGenerateRefreshTokenUseCase = class(TInterfacedObject, IGenerateRefreshTokenUseCase)
  private var
    FJWTManager: IJWTManager;
    FSigningSecret: string;
    FValidationSecret: string;

    function DoGenerateJwt(const Id: TGuid): IShared<TJwt>;
    function DoSignToken(const Token: IShared<TJwt>): string;
  public
    constructor Create(const JWTManager: IJWTManager; const SigningSecret: string; const ValidationSecret: string);

    function Run(const UserId: TGuid): Context<string>;
  end;

implementation

{ TGenerateRefreshTokenUseCase }

function TGenerateRefreshTokenUseCase.DoGenerateJwt(const Id: TGuid): IShared<TJwt>;
begin
  Result := Shared.Make(FJWTManager.GenerateToken(Constants.JWT_ISSUER));
  Result.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);
  Result.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, Id.ToString);
end;

function TGenerateRefreshTokenUseCase.DoSignToken(const Token: IShared<TJwt>): string;
begin
  Result := FJWTManager.SignTokenAndReturn(Token, TJOSEAlgorithmId.RS512, FSigningSecret, FValidationSecret);
end;

function TGenerateRefreshTokenUseCase.Run(const UserId: TGuid): Context<string>;
begin
  Result := &Try<IShared<TJwt>>.
    New(Context<TGuid>.
      New(UserId).
      Map<IShared<TJwt>>(DoGenerateJwt)).
    Map<string>(DoSignToken).
    Match(EGenerateRefreshTokenUseCase);
end;

constructor TGenerateRefreshTokenUseCase.Create(
  const JWTManager: IJWTManager;
  const SigningSecret: string;
  const ValidationSecret: string);
begin
  inherited Create;

  FJWTManager := Utilities.CheckNotNullAndSet(JWTManager, 'JWTManager');
  FSigningSecret := SigningSecret;
  FValidationSecret := ValidationSecret;
end;

end.
