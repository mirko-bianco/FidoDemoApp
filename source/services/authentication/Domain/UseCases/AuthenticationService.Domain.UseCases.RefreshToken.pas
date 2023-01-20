unit AuthenticationService.Domain.UseCases.RefreshToken;

interface

uses
  System.SysUtils,
  Generics.Collections,

  JOSE.Core.JWT,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.JWT.Manager.Intf,

  FidoApp.Constants,

  AuthenticationService.Domain.UseCases.Types,
  AuthenticationService.Domain.UseCases.RefreshToken.Intf,
  AuthenticationService.Domain.UseCases.GenerateRefreshToken.Intf,
  AuthenticationService.Domain.UseCases.GenerateAccessToken.Intf,
  AuthenticationService.Domain.TokensCache.Intf;

type
  TRefreshTokenUseCase = class(TInterfacedObject, IRefreshTokenUseCase)
  private type
    TTokenParams = record
    private
      FToken: string;
      FJWT: IShared<TJwt>;
    public
      constructor Create(const Token: string; const JWT: TJwt);

      property Token: string read FToken;
      function JWT: TJwt;
    end;
    TTokenAndIdParams = record
    private
      FToken: string;
      FId: TGuid;
    public
      constructor Create(const Token: string; const Id: TGuid);

      property Token: string read FToken;
      property Id: TGuid read FId;
    end;
    TIdAndTokensParams = record
    private
      FId: TGuid;
      FTokens: TTokens;
    public
      constructor Create(const Id: TGuid; const Tokens: TTokens);

      property Id: TGuid read FId;
      property Tokens: TTokens read FTokens;
    end;
  private var
    FJWTManager: IJWTManager;
    FValidationSecret: string;
    FGenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
    FGenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
    FTokensCache: IServerTokensCache;

    function CheckClaims(const Params: TTokenParams): TTokenParams;
    function ExtractUserId(const Params: TTokenParams): TTokenAndIdParams;
    function DoVerifyToken(const Token: string): TTokenParams;
    function DoCacheToken(const Params: TTokenAndIdParams): TGuid;
    function DoGenerateAccessToken(const Id: TGuid): TIdAndTokensParams;
    function DoGenerateRefreshToken(const Params: TIdAndTokensParams): TIdAndTokensParams;
    function DoValidateToken(const Params: TIdAndTokensParams): TTokens;
  public
    constructor Create(const JWTManager: IJWTManager; const GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase; const GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
      const ValidationSecret: string; const TokensCache: IServerTokensCache);

    function Run(const RefreshToken: string): Context<TTokens>;
  end;

implementation

{ TRefreshTokenUseCase }

constructor TRefreshTokenUseCase.Create(
  const JWTManager: IJWTManager;
  const GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  const GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  const ValidationSecret: string;
  const TokensCache: IServerTokensCache);
begin
  inherited Create;

  FJWTManager := Utilities.CheckNotNullAndSet(JWTManager, 'JWTManager');
  FValidationSecret := ValidationSecret;
  FGenerateAccessTokenUseCase := Utilities.CheckNotNullAndSet(GenerateAccessTokenUseCase, 'GenerateAccessTokenUseCase');
  FGenerateRefreshTokenUseCase := Utilities.CheckNotNullAndSet(GenerateRefreshTokenUseCase, 'GenerateRefreshTokenUseCase');
  FTokensCache := Utilities.CheckNotNullAndSet(TokensCache, 'TokensCache');
end;

function TRefreshTokenUseCase.CheckClaims(const Params: TTokenParams): TTokenParams;
var
  Jwt: TJwt;
begin
  Result := Params;
  Jwt := Params.Jwt;

  if not Assigned(Jwt.Claims.JSON.GetValue(Constants.CLAIM_TYPE)) then
    raise ERefreshTokenUseCaseValidation.Create('Invalid token.');

  if not Jwt.Claims.JSON.GetValue(Constants.CLAIM_TYPE).ToString.DeQuotedString('"').Equals(Constants.CLAIM_TYPE_REFRESH) then
    raise ERefreshTokenUseCaseValidation.Create('Invalid token.');

  if not Assigned(Jwt.Claims.JSON.GetValue(Constants.CLAIM_USERID)) then
    raise ERefreshTokenUseCaseValidation.Create('Invalid token.');
end;

function TRefreshTokenUseCase.ExtractUserId(const Params: TTokenParams): TTokenAndIdParams;
var
  UserId: TGuid;
  Jwt: TJwt;
begin
  Jwt := Params.Jwt;

  if not Utilities.TryStringToTGuid(Jwt.Claims.JSON.GetValue(Constants.CLAIM_USERID).ToString.DeQuotedString('"'), UserId) then
    raise ERefreshTokenUseCaseValidation.Create('Invalid token.');

  Result := TTokenAndIdParams.Create(Params.Token, UserId);
end;

function TRefreshTokenUseCase.DoVerifyToken(const Token: string): TTokenParams;
begin
  Result := TTokenParams.Create(
    Token,
    FJWTManager.VerifyToken(Token, FValidationSecret));

  if not Assigned(Result.JWT()) then
    raise ERefreshTokenUseCaseValidation.Create('Invalid token.');
end;

function TRefreshTokenUseCase.DoCacheToken(const Params: TTokenAndIdParams): TGuid;
begin
  Result := Params.Id;
  if not FTokensCache.Validate(Result, Params.Token) then
  begin
    FTokensCache.Invalidate(Result);
    raise ERefreshTokenUseCaseUnhauthorized.Create('Cache is not authorized.');
  end;
end;

function TRefreshTokenUseCase.DoGenerateAccessToken(const Id: TGuid): TIdAndTokensParams;
var
  Tokens: TTokens;
begin
  Tokens.AccessToken := FGenerateAccessTokenUseCase.Run(Id);
  Result := TIdAndTokensParams.Create(Id, Tokens);
end;

function TRefreshTokenUseCase.DoGenerateRefreshToken(const Params: TIdAndTokensParams): TIdAndTokensParams;
var
  Tokens: TTokens;
begin
  Tokens := Params.Tokens;
  Tokens.RefreshToken := FGenerateRefreshTokenUseCase.Run(Params.Id);
  Result := TIdAndTokensParams.Create(Params.Id, Tokens);
end;

function TRefreshTokenUseCase.DoValidateToken(const Params: TIdAndTokensParams): TTokens;
begin
  FTokensCache.Invalidate(Params.Id);
  FTokensCache.Validate(Params.Id, Params.Tokens.RefreshToken);
  Result := Params.Tokens;
end;

function TRefreshTokenUseCase.Run(const RefreshToken: string): Context<TTokens>;
begin
  Result := &Try<TIdAndTokensParams>.
    New(&Try<TGuid>.
      New(Context<string>.
        New(RefreshToken).
        Map<TTokenParams>(DoVerifyToken).
        Map<TTokenParams>(CheckClaims).
        Map<TTokenAndIdParams>(ExtractUserId).
        Map<TGuid>(DoCacheToken)).
      Map<TIdAndTokensParams>(DoGenerateAccessToken).
      Match(ERefreshTokenUseCaseValidation, 'Could not generate new access token. %s')).
    Map<TIdAndTokensParams>(DoGenerateRefreshToken).
    Match(ERefreshTokenUseCaseValidation, 'Could not generate new refresh token. %s').
    Map<TTokens>(DoValidateToken);
end;

{ TRefreshTokenUseCase.TTokenParams }

constructor TRefreshTokenUseCase.TTokenParams.Create(
  const Token: string;
  const JWT: TJwt);
begin
  FToken := Token;
  FJwt := Shared.Make(Jwt);
end;

function TRefreshTokenUseCase.TTokenParams.JWT: TJwt;
begin
  Result := FJWT;
end;

{ TRefreshTokenUseCase.TTokenAndIdParams }

constructor TRefreshTokenUseCase.TTokenAndIdParams.Create(
  const Token: string;
  const Id: TGuid);
begin
  FToken := Token;
  FId := Id;
end;

{ TRefreshTokenUseCase.TIdAndTokensParams }

constructor TRefreshTokenUseCase.TIdAndTokensParams.Create(
  const Id: TGuid;
  const Tokens: TTokens);
begin
  FId := Id;
  FTokens := Tokens;
end;

end.
