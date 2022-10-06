unit AuthenticationService.Domain.UseCases.Login;

interface

uses
  System.SysUtils,
  Generics.Collections,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,

  AuthenticationService.Domain.UseCases.Types,
  AuthenticationService.Domain.UseCases.Login.Intf,
  AuthenticationService.Domain.UseCases.GenerateAccessToken.Intf,
  AuthenticationService.Domain.UseCases.GenerateRefreshToken.Intf,
  AuthenticationService.Domain.Repositories.User.Intf,
  AuthenticationService.Domain.TokensCache.Intf,
  AuthenticationService.Domain.Entities.User;

type
  TLoginUseCase = class(TInterfacedObject, ILoginUseCase)
  private type
    TCacheData = record
    private
      FGuid: TGuid;
      FTokens: TTokens;
    public
      constructor Create(const Guid: TGuid; const Tokens: TTokens);

      property Guid: TGuid read FGuid;
      property Tokens: TTokens read FTokens;
    end;
  private var
    FGenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
    FGenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
    FRepositoryFactory: TFunc<IUserRepository>;
    FServerTokensCache: IServerTokensCache;

    function DoValidateUser(const User: TUser): TUser;
    function DoLogin(const User: TUser): Context<TGuid>;
    function DoInvalidateCache(const UserId: TGuid): TCacheData;
    function DoGenerateAccessToken(const Params: TCacheData): TCacheData;
    function DoGenerateRefreshToken(const Params: TCacheData): TCacheData;
    function DoValidateCache(const Params: TCacheData): TTokens;
  public
    constructor Create(const GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase; const GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase; const RepositoryFactory: TFunc<IUserRepository>;
      const ServerTokensCache: IServerTokensCache);

    function Run(const User: TUser): Context<TTokens>;
  end;

implementation

{ TAuthenticationUseCaseLogin }

constructor TLoginUseCase.Create(
  const GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  const GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  const RepositoryFactory: TFunc<IUserRepository>;
  const ServerTokensCache: IServerTokensCache);
begin
  inherited Create;

  FGenerateAccessTokenUseCase := Utilities.CheckNotNullAndSet(GenerateAccessTokenUseCase, 'GenerateAccessTokenUseCase');
  FGenerateRefreshTokenUseCase := Utilities.CheckNotNullAndSet(GenerateRefreshTokenUseCase, 'GenerateRefreshTokenUseCase');
  FRepositoryFactory := Utilities.CheckNotNullAndSet<TFunc<IUserRepository>>(RepositoryFactory, 'RepositoryFactory');
  FServerTokensCache := Utilities.CheckNotNullAndSet(ServerTokensCache, 'ServerTokensCache');
end;

function TLoginUseCase.DoValidateUser(const User: TUser): TUser;
begin
  Result := User;
  User.Validate;
end;

function TLoginUseCase.DoLogin(const User: TUser): Context<TGuid>;
begin
  Result := FRepositoryFactory().Login(User);
end;

function TLoginUseCase.DoInvalidateCache(const UserId: TGuid): TCacheData;
var
  Tokens: TTokens;
begin
  Result := TCacheData.Create(UserId, Tokens);

  FServerTokensCache.Invalidate(UserId);
end;

function TLoginUseCase.DoGenerateAccessToken(const Params: TCacheData): TCacheData;
var
  Tokens: TTokens;
begin
  Tokens := Params.Tokens;
  Tokens.AccessToken := FGenerateAccessTokenUseCase.Run(Params.Guid);
  Result := TCacheData.Create(Params.Guid, Tokens);
end;

function TLoginUseCase.DoGenerateRefreshToken(const Params: TCacheData): TCacheData;
var
  Tokens: TTokens;
begin
  Tokens := Params.Tokens;
  Tokens.RefreshToken := FGenerateRefreshTokenUseCase.Run(Params.Guid);
  Result := TCacheData.Create(Params.Guid, Tokens);
end;

function TLoginUseCase.DoValidateCache(const Params: TCacheData): TTokens;
begin
  Result := Params.Tokens;
  if not FServerTokensCache.Validate(Params.Guid, Result.RefreshToken) then
    raise ELoginUseCaseFailure.Create('Could not cache the tokens.');
end;

function TLoginUseCase.Run(const User: TUser): Context<TTokens>;
begin
  Result := &Try<TCacheData>.
    New(&Try<TCacheData>.
      New(&Try<TUser>.
        New(&Try<TUser>.
          New(User).
          Map<TUser>(DoValidateUser).
          Match(ELoginUseCaseValidation)).
        Map<TGuid>(DoLogin).
        Match(ELoginUseCaseFailure, 'Login failed.').
        Map<TCacheData>(DoInvalidateCache)).
      Map<TCacheData>(DoGenerateAccessToken).
      Match(ELoginUseCaseFailure, 'Could not generate the access token.')).
    Map<TCacheData>(DoGenerateRefreshToken).
    Match(ELoginUseCaseFailure, 'Could not generate the refresh token.').
    Map<TTokens>(DoValidateCache);
end;

{ TLoginUseCase.TCacheData }

constructor TLoginUseCase.TCacheData.Create(const Guid: TGuid; const Tokens: TTokens);
begin
  FGuid := Guid;
  FTokens := Tokens;
end;

end.
