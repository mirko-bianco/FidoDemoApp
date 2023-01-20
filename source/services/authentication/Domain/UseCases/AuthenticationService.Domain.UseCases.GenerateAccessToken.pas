unit AuthenticationService.Domain.UseCases.GenerateAccessToken;

interface

uses
  System.SysUtils,
  System.JSON,
  Generics.Collections,

  JOSE.Core.JWA,
  JOSE.Core.JWT,

  Spring,

  Fido.Utilities,
  Fido.Exceptions,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Types,
  Fido.JWT.Manager.Intf,
  Fido.JSON.Marshalling,

  FidoApp.Constants,
  FidoApp.Types,
  FidoApp.Domain.ClientTokensCache.Intf,

  AuthenticationService.Domain.UseCases.GenerateAccessToken.Intf,
  AuthenticationService.Domain.UseCases.AddRoleToToken.Intf;

type
  TGenerateAccessTokenUseCase = class(TInterfacedObject, IGenerateAccessTokenUseCase)
   private Type
    TJwtTokens = record
    private
      FAccessToken: IShared<TJwt>;
      FRefreshToken: IShared<TJwt>;
    public
      constructor Create(const AccessToken: TJwt; const RefreshToken: TJwt);

      function AccessToken: TJwt;
      function RefreshToken: TJwt;
    end;
  private var
    FJWTManager: IJWTManager;
    FSigningSecret: string;
    FValidationSecret: string;
    FAddRoleToTokenUseCase: IAddRoleToTokenUseCase;
    FClientTokensCache: IClientTokensCache;

    function DoGenerateTokens(const Id: string): TJwtTokens;
    function DoSignAndCacheTokens(const Tokens: TJwtTokens): TJwtTokens;
    function DoAddRoleToToken(const Tokens: TJwtTokens): TJwtTokens;
    function DoSignToken(const Tokens: TJwtTokens): string;
  public
    constructor Create(const JWTManager: IJWTManager; const AddRoleToTokenUseCase: IAddRoleToTokenUseCase; const SigningSecret: string; const ValidationSecret: string;
      const ClientTokensCache: IClientTokensCache);

    function Run(const UserId: TGuid): Context<string>;
  end;

implementation

{ TGenerateAccessTokenUseCase }

function TGenerateAccessTokenUseCase.DoGenerateTokens(const Id: string): TJwtTokens;
var
  AccessToken: TJwt;
  RefreshToken: TJwt;
begin
  AccessToken := FJWTManager.GenerateToken(Constants.JWT_ISSUER, Constants.JWT_ACCESS_TOKEN_LIFETIME_SECS);

  AccessToken.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_ACCESS);
  AccessToken.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, Id);
  AccessToken.Claims.Expiration := Now + Constants.JWT_ACCESS_TOKEN_LIFETIME_SECS * 24 / 60 / 60;

  RefreshToken := FJWTManager.GenerateToken(Constants.JWT_ISSUER, Constants.JWT_ACCESS_TOKEN_LIFETIME_SECS);

  RefreshToken.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);
  RefreshToken.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, Id);

  Result := TJwtTokens.Create(AccessToken, RefreshToken);
end;

function TGenerateAccessTokenUseCase.DoSignAndCacheTokens(const Tokens: TJwtTokens): TJwtTokens;
var
  CompactAccessToken: string;
  CompactRefreshToken: string;
begin
  CompactAccessToken := FJWTManager.SignTokenAndReturn(Tokens.AccessToken, TJOSEAlgorithmId.RS512, FSigningSecret, FValidationSecret);
  CompactRefreshToken := FJWTManager.SignTokenAndReturn(Tokens.RefreshToken, TJOSEAlgorithmId.RS512, FSigningSecret, FValidationSecret);

  FClientTokensCache.SetTokens(JSONUnmarshaller.To<ITokens>(Format('{"AccessToken": "%s", "RefreshToken": "%s"}', [CompactAccessToken, CompactRefreshToken])));

  Result := Tokens;
end;

function TGenerateAccessTokenUseCase.DoAddRoleToToken(const Tokens: TJwtTokens): TJwtTokens;
begin
  Result := Tokens;

  FAddRoleToTokenUseCase.Run(Tokens.AccessToken).Value;
end;

function TGenerateAccessTokenUseCase.DoSignToken(const Tokens: TJwtTokens): string;
begin
  Result := FJWTManager.SignTokenAndReturn(Tokens.AccessToken, TJOSEAlgorithmId.RS512, FSigningSecret, FValidationSecret);
end;

function TGenerateAccessTokenUseCase.Run(const UserId: TGuid): Context<string>;
begin
  Result := &Try<TJwtTokens>.
    New(Context<string>.
      New(UserId.ToString).
      Map<TJwtTokens>(DoGenerateTokens).
      Map<TJwtTokens>(DoSignAndCacheTokens).
      Map<TJwtTokens>(DoAddRoleToToken)).
    Map<string>(DoSignToken).
    Match(EGenerateAccessTokenUseCase);
end;

constructor TGenerateAccessTokenUseCase.Create(
  const JWTManager: IJWTManager;
  const AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  const SigningSecret: string;
  const ValidationSecret: string;
  const ClientTokensCache: IClientTokensCache);
begin
  inherited Create;

  FJWTManager := Utilities.CheckNotNullAndSet(JWTManager, 'JWTManager');
  FAddRoleToTokenUseCase := Utilities.CheckNotNullAndSet(AddRoleToTokenUseCase, 'AddRoleToTokenUseCase');
  FSigningSecret := SigningSecret;
  FValidationSecret := ValidationSecret;
  FClientTokensCache := Utilities.CheckNotNullAndSet(ClientTokensCache, 'ClientTokensCache');
end;

{ TGenerateAccessTokenUseCase.TJwtTokens }

function TGenerateAccessTokenUseCase.TJwtTokens.AccessToken: TJwt;
begin
  Result := FAccessToken;
end;

constructor TGenerateAccessTokenUseCase.TJwtTokens.Create(
  const AccessToken: TJwt;
  const RefreshToken: TJwt);
begin
  FAccessToken := Shared.Make(AccessToken);
  FRefreshToken := Shared.Make(RefreshToken);
end;

function TGenerateAccessTokenUseCase.TJwtTokens.RefreshToken: TJwt;
begin
  Result := FRefreshToken;
end;

end.
