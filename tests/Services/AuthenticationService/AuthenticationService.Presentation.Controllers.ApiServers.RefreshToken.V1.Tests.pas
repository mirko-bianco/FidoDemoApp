unit AuthenticationService.Presentation.Controllers.ApiServers.RefreshToken.V1.Tests;

interface

uses
  System.SysUtils,
  System.Hash,

  DUnitX.TestFramework,

  Spring,
  Spring.Logging,
  Spring.Mocking,
  Spring.Collections,

  JOSE.Core.JWT,
  JOSE.Core.JWA,

  Fido.Utilities,
  Fido.Exceptions,
  Fido.Types,
  Fido.Testing.Mock.Utils,
  Fido.JSON.Marshalling,
  Fido.Api.Server.Exceptions,
  Fido.JWT.Manager.Intf,
  Fido.JWT.Manager,
  Fido.Functional,

  FidoApp.Types,
  FidoApp.Constants,
  FidoApp.Domain.ClientTokensCache,
  FidoApp.Domain.ClientTokensCache.Intf,
  FidoApp.Persistence.ApiClients.Authorization.V1.Intf,
  FidoApp.Persistence.Gateways.Authorization.Intf,
  FidoApp.Persistence.Gateways.Authorization,

  AuthenticationService.Presentation.Controllers.ApiServers.RefreshToken.V1,
  AuthenticationService.Persistence.Repositories.UserRole,
  AuthenticationService.Domain.TokensCache.Intf,
  AuthenticationService.Domain.TokensCache.SingleInstance,
  AuthenticationService.Domain.Repositories.UserRole.Intf,
  AuthenticationService.Domain.Entities.UserStatus,
  AuthenticationService.Domain.UseCases.Types,
  AuthenticationService.Domain.UseCases.RefreshToken,
  AuthenticationService.Domain.UseCases.RefreshToken.Intf,
  AuthenticationService.Domain.UseCases.AddRoleToToken,
  AuthenticationService.Domain.UseCases.AddRoleToToken.Intf,
  AuthenticationService.Domain.UseCases.GenerateAccessToken,
  AuthenticationService.Domain.UseCases.GenerateAccessToken.Intf,
  AuthenticationService.Domain.UseCases.GenerateRefreshToken,
  AuthenticationService.Domain.UseCases.GenerateRefreshToken.Intf;

type
  EAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests = class(EFidoException);

  [TestFixture]
  TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests = class
  public
    [Test]
    procedure ExecuteReturnsTrueWhenRefreshSucceds;

    [Test]
    procedure ExecuteRaisesEApiServer400WhenRefreshTokenIsEmpty;

    [Test]
    procedure ExecuteRaisesEApiServer400WhenRefreshTokenIsRubbish;

    [Test]
    procedure ExecuteRaisesEApiServer400WhenRefreshTokenDoesNotContainUserId;

    [Test]
    procedure ExecuteRaisesEApiServer400WhenRefreshTokenUserIdIsNotValid;

    [Test]
    procedure ExecuteRaisesEApiServer400WhenRefreshTokenDoesNotHaveClaimType;

    [Test]
    procedure ExecuteRaisesEApiServer400WhenRefreshTokenHasWrongClaimType;

    [Test]
    procedure ExecuteRaisesEApiServer400WhenAccessTokenCannotBeGenerated;

    [Test]
    procedure ExecuteRaisesEApiServer400WhenRefreshTokenCannotBeGenerated;

    [Test]
    procedure ExecuteRaisesEApiServer401WhenRefreshTokenCannotBeCached;

    [Test]
    procedure ExecuteRaisesEApiServer500WhenTheUseCaseRaisesAnException;

    [Test]
    procedure ExecuteRaisesEApiServer401WhenHackedRefreshTokenIsUsed;
  end;

implementation

const
  SIGNINGSECRET =
'-----BEGIN RSA PRIVATE KEY-----'#13#10+
'MIIJKQIBAAKCAgEAu1Q14OKh0M9s6yDct6Ly4+Q2XU+KCT2I6LPXYb1XkTCOoZDD'#13#10+
'3W7vZauPncSn5nyFfgU/9aVIvdh9JOKfUq5bS7oejS4ooBjhvAhkRrSR41dyZu/c'#13#10+
'no+UE835JC8s1+/Nn4P/5jh3Ew1u5yw/PuKvYnruPI6jtmt44oJRN40G09EsCE/q'#13#10+
'fjqMHGZgqExXH3cjrXf9wENZ2qsSIhVj3pjRQQ3TEgyj13E5rfIZjidpHMwqBz1Y'#13#10+
'Gn/ZDMtCxWjE5nQLZGXfnPerfh/HRWRBIp4TI3itYkdgBx2/b0dBs8NENfJH+PTK'#13#10+
'bJvzHsbsGa9uLC9DwfeqcNuxqKaiv9s7bIpT0K1JriN/efzXZ1S+HK1T5GEZasfB'#13#10+
'NRGwLhniCyW16ECMXuObQyvb7UXbOIiUIi77y1Vi46kwnnoWY59kZBd0layR5hW4'#13#10+
'pWP7SwraDqCOCQCppvcATNq6pMmf11VonNRbk1EMjisFWDHYiTD/guKSW9hq8o40'#13#10+
'vYx1ro1iSn/PO5Ph76x7c/ax3xMk6D//AWCt7s5WJsfuacjnnQ+FH/b4ODpqEktm'#13#10+
'MATbGtVr3YSfFzaWR9kVhYUzM8u0t5j3Nnacob6G676OqELVpZSgRBgd4RI5jkNw'#13#10+
'tH/1AtJpWzthtTBnyEvxWtAmVKvfDaR4F4hyyXzwVxRAbn7Sv0E2x5fKGD0CAwEA'#13#10+
'AQKCAgEAtnGpl8CiAJBEcCutS1x0Wudk2zQgKCe6M4kT96lEo686+rfXSs5EcizI'#13#10+
'zss9CwmzqazLQh8b3Wn/V/EvYoNVf0dhgfa2slYJY+x4XTR38Ya1cPOjVvpXKYKt'#13#10+
'Z0Ra1GRFS1pv3HSZ5ABtRtCdOE3mqm83n9r8Lyo0rcZl+0hqodlSnTXYF+BFnVNI'#13#10+
'SCExqP+Ly+LVTG9MD+AU5QUYIy+KfWVNcILG/4jSuErWAND5WoatWCeyqvxhFEjS'#13#10+
'WxlSy2+xuLJPOr0sVMX2eerOVTzHPwDFPLZvG/8o9uPbZYyD3lZ9Kkae73BjNFJg'#13#10+
'mBN3pajSwRLI+Om++ZZxY5HNKkT+os91BTiF/yUuqhC/8x0XvU0iq3oR6FDwGITU'#13#10+
'lcoRvWtMOjqbS7r0tmKna4YPaaUft1WjexHjYsyDvQG0o+l+5j5h22Swu5WAfl/Y'#13#10+
'tYyLhSiIvxf1jz80B5Rlt+7fvqInpW7yzUZy/ewIqXtDAr6+VFT90m0Zv3FKEWw2'#13#10+
'TYYSWAU4v+XQmjWt2i+0b0wOqj5w19KlU3Rpl0Xu9HsTwfAWmZJ8zQZfIEml+Yri'#13#10+
'fLF16Vanflf8+0pcql1zHUPLL8gfs7etie7g8obBMLb8Yhul5NOYfaRHbYezWIpk'#13#10+
'd7HyzslH3F74js4Z8BCZMccP19HTXbrh2QSWbCytaud2euugsTECggEBAOQ8sQuL'#13#10+
'nWL/gnzNfO3LUEqOpZ47BPyMXzlltd1M2ZORyFsoMUqHq0n4w4BDJiESv7fjGycg'#13#10+
'SI0kmbKbkySoc+AVMLwVp9b2sK0SXLpmCghkuRnKUX9rRkQUDbqdhS2Y6YfPEC4I'#13#10+
'x6l2D2kFPq6lWtjPGZkmbAHq4FQEz7dV1r8NTEg+FuRtwX8Y1In7mGtMQOSwQyel'#13#10+
'NqeoeMNQgvYjsGRLzVu61jKQ2xNoBSh6r4Wb49tsZkBh7rYMmEJN3GCfKCfEnNVf'#13#10+
'+7umFq3k57CXnkFOLg//jaCSzopGhcysnHwfMNX7XXtQHrO22FYHTuFQa8MoqEtX'#13#10+
'J3LggQxyjZr8/HsCggEBANIdo4CrTM9Oyt8/XTqvYI3Wu1tdVR1eS6P3dBtpTM54'#13#10+
'ZFrVMjrpgGDN+jdsVtsxTT3/zfDxqJBlyloxHz8OGjSK2e8sjx37tzHHCBPf9J8s'#13#10+
'l97DsaKwUpmUJQgxUCXL9C8ETCtZoRO9qKCbFzHiTo254e3/CxVr4S2K3+ra6V2D'#13#10+
'zvyI9Whaan+xqXi0Z4rTrDK4RCJwhc1M1TqjKY6+1WqiyZFmPhRtPgmt87ax9VFT'#13#10+
'YLRAArLbfIVoOlPR8VO9/jQrRZqr+ygVVHCBeRbgLkZhwMLpSp7CKDn3SMnvP/Yd'#13#10+
'KAOR23xdMFwyZvFaFlfN5qDuUKJQUcRfHP5LaYwA7KcCggEBAN55MnJ4kt+PBBi3'#13#10+
'DJGWXxtt1I5aJVAvXBrMw+uFH4iyz8Pbd8CYYiTmsVpzGdWfOvX6D9uholbCWHc7'#13#10+
'IsDW2qyQu0J7MXFeYXUysuSW1iy8UZmMFsjHPmTZz1Aaf1ik9u4ErlbRBB5xEDBk'#13#10+
'hmcik11G8kLQqvNriWMclYS1zW/JfJPmwdXEDprfDz242yer2o2QKsWYS6A9ngl0'#13#10+
'j1NyElyRbwl9I5GClali+bQtcq4f+IlILpuPWmpl+HyY/LnKKhApnF55Ax40lWLH'#13#10+
'//eoswAhPtElX14n+9/ZQk7x6k8q8CWEseijfmnbTyD8Wq1SANjo5rMZr0BRCjmh'#13#10+
'59otw8UCggEAIyoCqw4AFNHC8gnQuHmRVyuQv4GnNPsK/a30KII+8G8FnI4Bkgpy'#13#10+
'CcFvFsdy4cwmeTHObXyEEWZ3rxB5gjwB9rkmL/jtGr99sT72Ax1/+wOjhwyJNgj8'#13#10+
'SeeZKv3Vw/2WKCg39ylQ49Th278Y6qhNLTrmrMX6POOJE+4h+1QXqibdBTaGm6hG'#13#10+
'GojJLAJFMd6q+vILtRfPzMQHC4Ey+0jEvsvvn/3UdeayczxBhVnTDIE/tergiL5i'#13#10+
'4JDI8i44jSNG38Q+KdyOc+7d6tZARavPEshZUkVoz5j+0nSoIeOAeNf4UmCesvmF'#13#10+
'lmh5AftpsdgruNMpe4Clro+ccpJ8X4noEQKCAQBoUHZG+7P/VQekNey9O9TSf869'#13#10+
'LPRE/rMVlDCtQqD/NUWqFWKrbyCMIyzsGzhxGUpM7WHnUpntwIrs50R4N+3OybiE'#13#10+
'nWf42xXrR/kOrI229Q86bKCH1w5a6TTxnNN4mcl76vILstHNp9NgSs/umx8ml0fb'#13#10+
'8KuW9jVUlFrpO7pj9Sr4LRaIfF9g/EoMvrPIAOUsROamcXORzVaJBAHLWRUiPc4u'#13#10+
'kYcQ4niDfKmY3c9V60Esp75l3xb6HaqvNuIUJQNSeKqwucjPvKFgdFBSwBkiEsgo'#13#10+
'bSjBqncHkzZfBjK9JmQZPAVOMdqIGcuZ6PEO2w8NAXpRjmMmXT+oFppe48vV'#13#10+
'-----END RSA PRIVATE KEY-----';
  VALIDATIONSECRET =
'-----BEGIN PUBLIC KEY-----'#13#10+
'MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAu1Q14OKh0M9s6yDct6Ly'#13#10+
'4+Q2XU+KCT2I6LPXYb1XkTCOoZDD3W7vZauPncSn5nyFfgU/9aVIvdh9JOKfUq5b'#13#10+
'S7oejS4ooBjhvAhkRrSR41dyZu/cno+UE835JC8s1+/Nn4P/5jh3Ew1u5yw/PuKv'#13#10+
'YnruPI6jtmt44oJRN40G09EsCE/qfjqMHGZgqExXH3cjrXf9wENZ2qsSIhVj3pjR'#13#10+
'QQ3TEgyj13E5rfIZjidpHMwqBz1YGn/ZDMtCxWjE5nQLZGXfnPerfh/HRWRBIp4T'#13#10+
'I3itYkdgBx2/b0dBs8NENfJH+PTKbJvzHsbsGa9uLC9DwfeqcNuxqKaiv9s7bIpT'#13#10+
'0K1JriN/efzXZ1S+HK1T5GEZasfBNRGwLhniCyW16ECMXuObQyvb7UXbOIiUIi77'#13#10+
'y1Vi46kwnnoWY59kZBd0layR5hW4pWP7SwraDqCOCQCppvcATNq6pMmf11VonNRb'#13#10+
'k1EMjisFWDHYiTD/guKSW9hq8o40vYx1ro1iSn/PO5Ph76x7c/ax3xMk6D//AWCt'#13#10+
'7s5WJsfuacjnnQ+FH/b4ODpqEktmMATbGtVr3YSfFzaWR9kVhYUzM8u0t5j3Nnac'#13#10+
'ob6G676OqELVpZSgRBgd4RI5jkNwtH/1AtJpWzthtTBnyEvxWtAmVKvfDaR4F4hy'#13#10+
'yXzwVxRAbn7Sv0E2x5fKGD0CAwEAAQ=='#13#10+
'-----END PUBLIC KEY-----';

{ TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests }

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteRaisesEApiServer400WhenRefreshTokenIsRubbish;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: IRefreshTokenUseCase;
  GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  JwtManager: IJwtManager;
  AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  UserRoleRepository: IUserRoleRepository;
  AuthorizationV1ApiClientGateway: IAuthorizationV1ApiClientGateway;
  AuthorizationV1ApiClient: Mock<IAuthorizationV1ApiClient>;
  ClientTokensCache: IClientTokensCache;
  GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  ServerTokensCache: IServerTokensCache;

  UserRole: Mock<IUserRoleAndPermissions>;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UserRole := Mock<IUserRoleAndPermissions>.Create;
  UserRole.Setup.Returns<string>('user').When.Role;
  UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

  AuthorizationV1ApiClient := Mock<IAuthorizationV1ApiClient>.Create;
  AuthorizationV1ApiClient.Setup.Returns<IUserRoleAndPermissions>(UserRole).When.GetRole;

  AuthorizationV1ApiClientGateway := TAuthorizationV1ApiClientGateway.Create(AuthorizationV1ApiClient);

  UserRoleRepository := TUserRoleRepository.Create(AuthorizationV1ApiClientGateway);

  AddRoleToTokenUseCase := TAddRoleToTokenUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := UserRoleRepository;
    end);

  ClientTokensCache := TClientTokensCache.Create;

  GenerateAccessTokenUseCase := TGenerateAccessTokenUseCase.Create(
    JwtManager,
    AddRoleToTokenUseCase,
    SIGNINGSECRET,
    VALIDATIONSECRET,
    ClientTokensCache);

  GenerateRefreshTokenUseCase := TGenerateRefreshTokenUseCase.Create(
    JwtManager,
    SIGNINGSECRET,
    VALIDATIONSECRET);

  ServerTokensCache := TSingleInstanceServerTokensCache.Create;

  UseCase := TRefreshTokenUseCase.Create(
    JwtManager,
    GenerateAccessTokenUseCase,
    GenerateRefreshTokenUseCase,
    VALIDATIONSECRET,
    ServerTokensCache);

  Resource := TRefreshTokenV1ApiServerController.Create(UseCase);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(MockUtils.SomeString, Authorization, RefreshToken);
    end,
    EApiServer400);

  AuthorizationV1ApiClient.Received(Times.Never).GetRole;
end;

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteRaisesEApiServer400WhenRefreshTokenUserIdIsNotValid;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: IRefreshTokenUseCase;
  GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  JwtManager: IJwtManager;
  AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  UserRoleRepository: IUserRoleRepository;
  AuthorizationV1ApiClientGateway: IAuthorizationV1ApiClientGateway;
  AuthorizationV1ApiClient: Mock<IAuthorizationV1ApiClient>;
  ClientTokensCache: IClientTokensCache;
  GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  ServerTokensCache: IServerTokensCache;

  UserRole: Mock<IUserRoleAndPermissions>;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;

  CurrentRefreshJwt: Shared<TJwt>;
  CurrentRefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UserRole := Mock<IUserRoleAndPermissions>.Create;
  UserRole.Setup.Returns<string>('user').When.Role;
  UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

  AuthorizationV1ApiClient := Mock<IAuthorizationV1ApiClient>.Create;
  AuthorizationV1ApiClient.Setup.Returns<IUserRoleAndPermissions>(UserRole).When.GetRole;

  AuthorizationV1ApiClientGateway := TAuthorizationV1ApiClientGateway.Create(AuthorizationV1ApiClient);

  UserRoleRepository := TUserRoleRepository.Create(AuthorizationV1ApiClientGateway);

  AddRoleToTokenUseCase := TAddRoleToTokenUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := UserRoleRepository;
    end);

  ClientTokensCache := TClientTokensCache.Create;

  GenerateAccessTokenUseCase := TGenerateAccessTokenUseCase.Create(
    JwtManager,
    AddRoleToTokenUseCase,
    SIGNINGSECRET,
    VALIDATIONSECRET,
    ClientTokensCache);

  GenerateRefreshTokenUseCase := TGenerateRefreshTokenUseCase.Create(
    JwtManager,
    SIGNINGSECRET,
    VALIDATIONSECRET);

  ServerTokensCache := TSingleInstanceServerTokensCache.Create;

  UseCase := TRefreshTokenUseCase.Create(
    JwtManager,
    GenerateAccessTokenUseCase,
    GenerateRefreshTokenUseCase,
    VALIDATIONSECRET,
    ServerTokensCache);

  Resource := TRefreshTokenV1ApiServerController.Create(UseCase);

  CurrentRefreshJwt := JwtManager.GenerateToken('');
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, MockUtils.SomeString);
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);
  CurrentRefreshToken := JwtManager.SignTokenAndReturn(CurrentRefreshJwt, TJOSEAlgorithmId.RS512, SIGNINGSECRET, VALIDATIONSECRET);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(CurrentRefreshToken, Authorization, RefreshToken);
    end,
    EApiServer400);

  AuthorizationV1ApiClient.Received(Times.Never).GetRole;
end;

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteRaisesEApiServer401WhenHackedRefreshTokenIsUsed;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: IRefreshTokenUseCase;
  GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  JwtManager: IJwtManager;
  AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  UserRoleRepository: IUserRoleRepository;
  AuthorizationV1ApiClientGateway: IAuthorizationV1ApiClientGateway;
  AuthorizationV1ApiClient: Mock<IAuthorizationV1ApiClient>;
  ClientTokensCache: IClientTokensCache;
  GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  ServerTokensCache: IServerTokensCache;

  UserRole: Mock<IUserRoleAndPermissions>;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;

  CurrentRefreshJwt: Shared<TJwt>;
  CurrentRefreshToken: string;

  HackedRefreshJwt: Shared<TJwt>;
  HackedRefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UserRole := Mock<IUserRoleAndPermissions>.Create;
  UserRole.Setup.Returns<string>('user').When.Role;
  UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

  AuthorizationV1ApiClient := Mock<IAuthorizationV1ApiClient>.Create;
  AuthorizationV1ApiClient.Setup.Returns<IUserRoleAndPermissions>(UserRole).When.GetRole;

  AuthorizationV1ApiClientGateway := TAuthorizationV1ApiClientGateway.Create(AuthorizationV1ApiClient);

  UserRoleRepository := TUserRoleRepository.Create(AuthorizationV1ApiClientGateway);

  AddRoleToTokenUseCase := TAddRoleToTokenUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := UserRoleRepository;
    end);

  ClientTokensCache := TClientTokensCache.Create;

  GenerateAccessTokenUseCase := TGenerateAccessTokenUseCase.Create(
    JwtManager,
    AddRoleToTokenUseCase,
    SIGNINGSECRET,
    VALIDATIONSECRET,
    ClientTokensCache);

  GenerateRefreshTokenUseCase := TGenerateRefreshTokenUseCase.Create(
    JwtManager,
    SIGNINGSECRET,
    VALIDATIONSECRET);

  ServerTokensCache := TSingleInstanceServerTokensCache.Create;

  UseCase := TRefreshTokenUseCase.Create(
    JwtManager,
    GenerateAccessTokenUseCase,
    GenerateRefreshTokenUseCase,
    VALIDATIONSECRET,
    ServerTokensCache);

  Resource := TRefreshTokenV1ApiServerController.Create(UseCase);

  CurrentRefreshJwt := JwtManager.GenerateToken('');
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, UserId.ToString);
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);
  CurrentRefreshToken := JwtManager.SignTokenAndReturn(CurrentRefreshJwt, TJOSEAlgorithmId.RS512, SIGNINGSECRET, VALIDATIONSECRET);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Resource.Value.Execute(CurrentRefreshToken, Authorization, RefreshToken);
    end);

  HackedRefreshJwt := JwtManager.GenerateToken('');
  HackedRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, UserId.ToString);
  HackedRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);
  HackedRefreshToken := JwtManager.SignTokenAndReturn(CurrentRefreshJwt, TJOSEAlgorithmId.RS512, SIGNINGSECRET, VALIDATIONSECRET);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(HackedRefreshToken, Authorization, RefreshToken);
    end,
    EApiServer401);
end;

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteRaisesEApiServer500WhenTheUseCaseRaisesAnException;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: Mock<IRefreshTokenUseCase>;
  JwtManager: IJwtManager;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;

  CurrentRefreshJwt: Shared<TJwt>;
  CurrentRefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UseCase := Mock<IRefreshTokenUseCase>.Create;
  UseCase.Setup.Returns<Context<TTokens>>(Context<TTokens>.New(function: TTokens
    begin
      raise EAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.Create('There is an error.');
    end)).When.Run(Arg.IsAny<string>);

  Resource := TRefreshTokenV1ApiServerController.Create(UseCase);

  CurrentRefreshJwt := JwtManager.GenerateToken('');
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, UserId.ToString);
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);
  CurrentRefreshToken := JwtManager.SignTokenAndReturn(CurrentRefreshJwt, TJOSEAlgorithmId.RS512, SIGNINGSECRET, VALIDATIONSECRET);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(CurrentRefreshToken, Authorization, RefreshToken);
    end,
    EAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests);
end;

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteReturnsTrueWhenRefreshSucceds;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: IRefreshTokenUseCase;
  GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  JwtManager: IJwtManager;
  AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  UserRoleRepository: IUserRoleRepository;
  AuthorizationV1ApiClientGateway: IAuthorizationV1ApiClientGateway;
  AuthorizationV1ApiClient: Mock<IAuthorizationV1ApiClient>;
  ClientTokensCache: IClientTokensCache;
  GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  ServerTokensCache: IServerTokensCache;

  UserRole: Mock<IUserRoleAndPermissions>;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;

  CurrentRefreshJwt: Shared<TJwt>;
  CurrentRefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UserRole := Mock<IUserRoleAndPermissions>.Create;
  UserRole.Setup.Returns<string>('user').When.Role;
  UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

  AuthorizationV1ApiClient := Mock<IAuthorizationV1ApiClient>.Create;
  AuthorizationV1ApiClient.Setup.Returns<IUserRoleAndPermissions>(UserRole).When.GetRole;

  AuthorizationV1ApiClientGateway := TAuthorizationV1ApiClientGateway.Create(AuthorizationV1ApiClient);

  UserRoleRepository := TUserRoleRepository.Create(AuthorizationV1ApiClientGateway);

  AddRoleToTokenUseCase := TAddRoleToTokenUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := UserRoleRepository;
    end);

  ClientTokensCache := TClientTokensCache.Create;

  GenerateAccessTokenUseCase := TGenerateAccessTokenUseCase.Create(
    JwtManager,
    AddRoleToTokenUseCase,
    SIGNINGSECRET,
    VALIDATIONSECRET,
    ClientTokensCache);

  GenerateRefreshTokenUseCase := TGenerateRefreshTokenUseCase.Create(
    JwtManager,
    SIGNINGSECRET,
    VALIDATIONSECRET);

  ServerTokensCache := TSingleInstanceServerTokensCache.Create;

  UseCase := TRefreshTokenUseCase.Create(
    JwtManager,
    GenerateAccessTokenUseCase,
    GenerateRefreshTokenUseCase,
    VALIDATIONSECRET,
    ServerTokensCache);

  Resource := TRefreshTokenV1ApiServerController.Create(UseCase);

  CurrentRefreshJwt := JwtManager.GenerateToken('');
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, UserId.ToString);
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);
  CurrentRefreshToken := JwtManager.SignTokenAndReturn(CurrentRefreshJwt, TJOSEAlgorithmId.RS512, SIGNINGSECRET, VALIDATIONSECRET);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.IsTrue(ServerTokensCache.Validate(UserId, CurrentRefreshToken));
      Resource.Value.Execute(CurrentRefreshToken, Authorization, RefreshToken);
    end);

  AuthorizationV1ApiClient.Received(Times.Once).GetRole;
end;

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteRaisesEApiServer400WhenAccessTokenCannotBeGenerated;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: IRefreshTokenUseCase;
  GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  JwtManager: IJwtManager;
  AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  UserRoleRepository: IUserRoleRepository;
  AuthorizationV1ApiClientGateway: IAuthorizationV1ApiClientGateway;
  AuthorizationV1ApiClient: Mock<IAuthorizationV1ApiClient>;
  ClientTokensCache: IClientTokensCache;
  GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  ServerTokensCache: IServerTokensCache;

  UserRole: Mock<IUserRoleAndPermissions>;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;

  CurrentRefreshJwt: Shared<TJwt>;
  CurrentRefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UserRole := Mock<IUserRoleAndPermissions>.Create;
  UserRole.Setup.Returns<string>('user').When.Role;
  UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

  AuthorizationV1ApiClient := Mock<IAuthorizationV1ApiClient>.Create;
  AuthorizationV1ApiClient.Setup.Returns<IUserRoleAndPermissions>(UserRole).When.GetRole;

  AuthorizationV1ApiClientGateway := TAuthorizationV1ApiClientGateway.Create(AuthorizationV1ApiClient);

  UserRoleRepository := TUserRoleRepository.Create(AuthorizationV1ApiClientGateway);

  AddRoleToTokenUseCase := TAddRoleToTokenUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := UserRoleRepository;
    end);

  ClientTokensCache := TClientTokensCache.Create;

  GenerateAccessTokenUseCase := TGenerateAccessTokenUseCase.Create(
    JwtManager,
    AddRoleToTokenUseCase,
    '',
    VALIDATIONSECRET,
    ClientTokensCache);

  GenerateRefreshTokenUseCase := TGenerateRefreshTokenUseCase.Create(
    JwtManager,
    SIGNINGSECRET,
    VALIDATIONSECRET);

  ServerTokensCache := TSingleInstanceServerTokensCache.Create;

  UseCase := TRefreshTokenUseCase.Create(
    JwtManager,
    GenerateAccessTokenUseCase,
    GenerateRefreshTokenUseCase,
    VALIDATIONSECRET,
    ServerTokensCache);

  Resource := TRefreshTokenV1ApiServerController.Create(UseCase);

  CurrentRefreshJwt := JwtManager.GenerateToken('');
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, UserId.ToString);
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);
  CurrentRefreshToken := JwtManager.SignTokenAndReturn(CurrentRefreshJwt, TJOSEAlgorithmId.RS512, SIGNINGSECRET, VALIDATIONSECRET);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(CurrentRefreshToken, Authorization, RefreshToken);
    end,
    EApiServer400);

  AuthorizationV1ApiClient.Received(Times.Never).GetRole;
end;

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteRaisesEApiServer401WhenRefreshTokenCannotBeCached;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: IRefreshTokenUseCase;
  GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  JwtManager: IJwtManager;
  AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  UserRoleRepository: IUserRoleRepository;
  AuthorizationV1ApiClientGateway: IAuthorizationV1ApiClientGateway;
  AuthorizationV1ApiClient: Mock<IAuthorizationV1ApiClient>;
  ClientTokensCache: IClientTokensCache;
  GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  ServerTokensCache: Mock<IServerTokensCache>;

  UserRole: Mock<IUserRoleAndPermissions>;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;

  CurrentRefreshJwt: Shared<TJwt>;
  CurrentRefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UserRole := Mock<IUserRoleAndPermissions>.Create;
  UserRole.Setup.Returns<string>('user').When.Role;
  UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

  AuthorizationV1ApiClient := Mock<IAuthorizationV1ApiClient>.Create;
  AuthorizationV1ApiClient.Setup.Returns<IUserRoleAndPermissions>(UserRole).When.GetRole;

  AuthorizationV1ApiClientGateway := TAuthorizationV1ApiClientGateway.Create(AuthorizationV1ApiClient);

  UserRoleRepository := TUserRoleRepository.Create(AuthorizationV1ApiClientGateway);

  AddRoleToTokenUseCase := TAddRoleToTokenUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := UserRoleRepository;
    end);

  ClientTokensCache := TClientTokensCache.Create;

  GenerateAccessTokenUseCase := TGenerateAccessTokenUseCase.Create(
    JwtManager,
    AddRoleToTokenUseCase,
    SIGNINGSECRET,
    VALIDATIONSECRET,
    ClientTokensCache);

  GenerateRefreshTokenUseCase := TGenerateRefreshTokenUseCase.Create(
    JwtManager,
    SIGNINGSECRET,
    VALIDATIONSECRET);

  ServerTokensCache := Mock<IServerTokensCache>.Create;
  ServerTokensCache.Setup.Executes.When.Invalidate(Arg.IsAny<TGuid>);
  ServerTokensCache.Setup.Returns<Boolean>([False]).When.Validate(Arg.IsAny<TGuid>, Arg.IsAny<string>);

  UseCase := TRefreshTokenUseCase.Create(
    JwtManager,
    GenerateAccessTokenUseCase,
    GenerateRefreshTokenUseCase,
    VALIDATIONSECRET,
    ServerTokensCache);

  Resource := TRefreshTokenV1ApiServerController.Create(

    UseCase);

  CurrentRefreshJwt := JwtManager.GenerateToken('');
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, UserId.ToString);
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);
  CurrentRefreshToken := JwtManager.SignTokenAndReturn(CurrentRefreshJwt, TJOSEAlgorithmId.RS512, SIGNINGSECRET, VALIDATIONSECRET);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(CurrentRefreshToken, Authorization, RefreshToken);
    end,
    EApiServer401);

  AuthorizationV1ApiClient.Received(Times.Never).GetRole;
end;

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteRaisesEApiServer400WhenRefreshTokenCannotBeGenerated;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: IRefreshTokenUseCase;
  GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  JwtManager: IJwtManager;
  AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  UserRoleRepository: IUserRoleRepository;
  AuthorizationV1ApiClientGateway: IAuthorizationV1ApiClientGateway;
  AuthorizationV1ApiClient: Mock<IAuthorizationV1ApiClient>;
  ClientTokensCache: IClientTokensCache;
  GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  ServerTokensCache: IServerTokensCache;

  UserRole: Mock<IUserRoleAndPermissions>;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;

  CurrentRefreshJwt: Shared<TJwt>;
  CurrentRefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UserRole := Mock<IUserRoleAndPermissions>.Create;
  UserRole.Setup.Returns<string>('user').When.Role;
  UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

  AuthorizationV1ApiClient := Mock<IAuthorizationV1ApiClient>.Create;
  AuthorizationV1ApiClient.Setup.Returns<IUserRoleAndPermissions>(UserRole).When.GetRole;

  AuthorizationV1ApiClientGateway := TAuthorizationV1ApiClientGateway.Create(AuthorizationV1ApiClient);

  UserRoleRepository := TUserRoleRepository.Create(AuthorizationV1ApiClientGateway);

  AddRoleToTokenUseCase := TAddRoleToTokenUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := UserRoleRepository;
    end);

  ClientTokensCache := TClientTokensCache.Create;

  GenerateAccessTokenUseCase := TGenerateAccessTokenUseCase.Create(
    JwtManager,
    AddRoleToTokenUseCase,
    SIGNINGSECRET,
    VALIDATIONSECRET,
    ClientTokensCache);

  GenerateRefreshTokenUseCase := TGenerateRefreshTokenUseCase.Create(
    JwtManager,
    '',
    VALIDATIONSECRET);

  ServerTokensCache := TSingleInstanceServerTokensCache.Create;

  UseCase := TRefreshTokenUseCase.Create(
    JwtManager,
    GenerateAccessTokenUseCase,
    GenerateRefreshTokenUseCase,
    VALIDATIONSECRET,
    ServerTokensCache);

  Resource := TRefreshTokenV1ApiServerController.Create(

    UseCase);

  CurrentRefreshJwt := JwtManager.GenerateToken('');
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, UserId.ToString);
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);
  CurrentRefreshToken := JwtManager.SignTokenAndReturn(CurrentRefreshJwt, TJOSEAlgorithmId.RS512, SIGNINGSECRET, VALIDATIONSECRET);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(CurrentRefreshToken, Authorization, RefreshToken);
    end,
    EApiServer400);

  AuthorizationV1ApiClient.Received(Times.Once).GetRole;
end;

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteRaisesEApiServer400WhenRefreshTokenDoesNotContainUserId;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: IRefreshTokenUseCase;
  GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  JwtManager: IJwtManager;
  AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  UserRoleRepository: IUserRoleRepository;
  AuthorizationV1ApiClientGateway: IAuthorizationV1ApiClientGateway;
  AuthorizationV1ApiClient: Mock<IAuthorizationV1ApiClient>;
  ClientTokensCache: IClientTokensCache;
  GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  ServerTokensCache: IServerTokensCache;

  UserRole: Mock<IUserRoleAndPermissions>;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;

  CurrentRefreshJwt: Shared<TJwt>;
  CurrentRefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UserRole := Mock<IUserRoleAndPermissions>.Create;
  UserRole.Setup.Returns<string>('user').When.Role;
  UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

  AuthorizationV1ApiClient := Mock<IAuthorizationV1ApiClient>.Create;
  AuthorizationV1ApiClient.Setup.Returns<IUserRoleAndPermissions>(UserRole).When.GetRole;

  AuthorizationV1ApiClientGateway := TAuthorizationV1ApiClientGateway.Create(AuthorizationV1ApiClient);

  UserRoleRepository := TUserRoleRepository.Create(AuthorizationV1ApiClientGateway);

  AddRoleToTokenUseCase := TAddRoleToTokenUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := UserRoleRepository;
    end);

  ClientTokensCache := TClientTokensCache.Create;

  GenerateAccessTokenUseCase := TGenerateAccessTokenUseCase.Create(
    JwtManager,
    AddRoleToTokenUseCase,
    SIGNINGSECRET,
    VALIDATIONSECRET,
    ClientTokensCache);

  GenerateRefreshTokenUseCase := TGenerateRefreshTokenUseCase.Create(
    JwtManager,
    SIGNINGSECRET,
    VALIDATIONSECRET);

  ServerTokensCache := TSingleInstanceServerTokensCache.Create;

  UseCase := TRefreshTokenUseCase.Create(
    JwtManager,
    GenerateAccessTokenUseCase,
    GenerateRefreshTokenUseCase,
    VALIDATIONSECRET,
    ServerTokensCache);

  Resource := TRefreshTokenV1ApiServerController.Create(

    UseCase);

  CurrentRefreshJwt := JwtManager.GenerateToken('');
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);
  CurrentRefreshToken := JwtManager.SignTokenAndReturn(CurrentRefreshJwt, TJOSEAlgorithmId.RS512, SIGNINGSECRET, VALIDATIONSECRET);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(CurrentRefreshToken, Authorization, RefreshToken);
    end,
    EApiServer400);

  AuthorizationV1ApiClient.Received(Times.Never).GetRole;
end;

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteRaisesEApiServer400WhenRefreshTokenDoesNotHaveClaimType;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: IRefreshTokenUseCase;
  GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  JwtManager: IJwtManager;
  AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  UserRoleRepository: IUserRoleRepository;
  AuthorizationV1ApiClientGateway: IAuthorizationV1ApiClientGateway;
  AuthorizationV1ApiClient: Mock<IAuthorizationV1ApiClient>;
  ClientTokensCache: IClientTokensCache;
  GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  ServerTokensCache: IServerTokensCache;

  UserRole: Mock<IUserRoleAndPermissions>;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;

  CurrentRefreshJwt: Shared<TJwt>;
  CurrentRefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UserRole := Mock<IUserRoleAndPermissions>.Create;
  UserRole.Setup.Returns<string>('user').When.Role;
  UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

  AuthorizationV1ApiClient := Mock<IAuthorizationV1ApiClient>.Create;
  AuthorizationV1ApiClient.Setup.Returns<IUserRoleAndPermissions>(UserRole).When.GetRole;

  AuthorizationV1ApiClientGateway := TAuthorizationV1ApiClientGateway.Create(AuthorizationV1ApiClient);

  UserRoleRepository := TUserRoleRepository.Create(AuthorizationV1ApiClientGateway);

  AddRoleToTokenUseCase := TAddRoleToTokenUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := UserRoleRepository;
    end);

  ClientTokensCache := TClientTokensCache.Create;

  GenerateAccessTokenUseCase := TGenerateAccessTokenUseCase.Create(
    JwtManager,
    AddRoleToTokenUseCase,
    SIGNINGSECRET,
    VALIDATIONSECRET,
    ClientTokensCache);

  GenerateRefreshTokenUseCase := TGenerateRefreshTokenUseCase.Create(
    JwtManager,
    SIGNINGSECRET,
    VALIDATIONSECRET);

  ServerTokensCache := TSingleInstanceServerTokensCache.Create;

  UseCase := TRefreshTokenUseCase.Create(
    JwtManager,
    GenerateAccessTokenUseCase,
    GenerateRefreshTokenUseCase,
    VALIDATIONSECRET,
    ServerTokensCache);

  Resource := TRefreshTokenV1ApiServerController.Create(

    UseCase);

  CurrentRefreshJwt := JwtManager.GenerateToken('');
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, UserId.ToString);
  CurrentRefreshToken := JwtManager.SignTokenAndReturn(CurrentRefreshJwt, TJOSEAlgorithmId.RS512, SIGNINGSECRET, VALIDATIONSECRET);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(CurrentRefreshToken, Authorization, RefreshToken);
    end,
    EApiServer400);

  AuthorizationV1ApiClient.Received(Times.Never).GetRole;
end;

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteRaisesEApiServer400WhenRefreshTokenHasWrongClaimType;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: IRefreshTokenUseCase;
  GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  JwtManager: IJwtManager;
  AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  UserRoleRepository: IUserRoleRepository;
  AuthorizationV1ApiClientGateway: IAuthorizationV1ApiClientGateway;
  AuthorizationV1ApiClient: Mock<IAuthorizationV1ApiClient>;
  ClientTokensCache: IClientTokensCache;
  GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  ServerTokensCache: IServerTokensCache;

  UserRole: Mock<IUserRoleAndPermissions>;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;

  CurrentRefreshJwt: Shared<TJwt>;
  CurrentRefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UserRole := Mock<IUserRoleAndPermissions>.Create;
  UserRole.Setup.Returns<string>('user').When.Role;
  UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

  AuthorizationV1ApiClient := Mock<IAuthorizationV1ApiClient>.Create;
  AuthorizationV1ApiClient.Setup.Returns<IUserRoleAndPermissions>(UserRole).When.GetRole;

  AuthorizationV1ApiClientGateway := TAuthorizationV1ApiClientGateway.Create(AuthorizationV1ApiClient);

  UserRoleRepository := TUserRoleRepository.Create(AuthorizationV1ApiClientGateway);

  AddRoleToTokenUseCase := TAddRoleToTokenUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := UserRoleRepository;
    end);

  ClientTokensCache := TClientTokensCache.Create;

  GenerateAccessTokenUseCase := TGenerateAccessTokenUseCase.Create(
    JwtManager,
    AddRoleToTokenUseCase,
    SIGNINGSECRET,
    VALIDATIONSECRET,
    ClientTokensCache);

  GenerateRefreshTokenUseCase := TGenerateRefreshTokenUseCase.Create(
    JwtManager,
    SIGNINGSECRET,
    VALIDATIONSECRET);

  ServerTokensCache := TSingleInstanceServerTokensCache.Create;

  UseCase := TRefreshTokenUseCase.Create(
    JwtManager,
    GenerateAccessTokenUseCase,
    GenerateRefreshTokenUseCase,
    VALIDATIONSECRET,
    ServerTokensCache);

  Resource := TRefreshTokenV1ApiServerController.Create(

    UseCase);

  CurrentRefreshJwt := JwtManager.GenerateToken('');
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_USERID, UserId.ToString);
  CurrentRefreshJwt.Value.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_ACCESS);
  CurrentRefreshToken := JwtManager.SignTokenAndReturn(CurrentRefreshJwt, TJOSEAlgorithmId.RS512, SIGNINGSECRET, VALIDATIONSECRET);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(CurrentRefreshToken, Authorization, RefreshToken);
    end,
    EApiServer400);

  AuthorizationV1ApiClient.Received(Times.Never).GetRole;
end;

procedure TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests.ExecuteRaisesEApiServer400WhenRefreshTokenIsEmpty;
var
  Resource: Shared<TRefreshTokenV1ApiServerController>;
  UseCase: IRefreshTokenUseCase;
  GenerateAccessTokenUseCase: IGenerateAccessTokenUseCase;
  JwtManager: IJwtManager;
  AddRoleToTokenUseCase: IAddRoleToTokenUseCase;
  UserRoleRepository: IUserRoleRepository;
  AuthorizationV1ApiClientGateway: IAuthorizationV1ApiClientGateway;
  AuthorizationV1ApiClient: Mock<IAuthorizationV1ApiClient>;
  ClientTokensCache: IClientTokensCache;
  GenerateRefreshTokenUseCase: IGenerateRefreshTokenUseCase;
  ServerTokensCache: IServerTokensCache;

  UserRole: Mock<IUserRoleAndPermissions>;

  UserId: TGuid;
  Username: string;
  Password: string;
  Authorization: string;
  RefreshToken: string;
begin
  UserId := MockUtils.SomeGuid;
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdfsdfsdf';

  JwtManager := TJwtManager.Create;

  UserRole := Mock<IUserRoleAndPermissions>.Create;
  UserRole.Setup.Returns<string>('user').When.Role;
  UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

  AuthorizationV1ApiClient := Mock<IAuthorizationV1ApiClient>.Create;
  AuthorizationV1ApiClient.Setup.Returns<IUserRoleAndPermissions>(UserRole).When.GetRole;

  AuthorizationV1ApiClientGateway := TAuthorizationV1ApiClientGateway.Create(AuthorizationV1ApiClient);

  UserRoleRepository := TUserRoleRepository.Create(AuthorizationV1ApiClientGateway);

  AddRoleToTokenUseCase := TAddRoleToTokenUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := UserRoleRepository;
    end);

  ClientTokensCache := TClientTokensCache.Create;

  GenerateAccessTokenUseCase := TGenerateAccessTokenUseCase.Create(
    JwtManager,
    AddRoleToTokenUseCase,
    SIGNINGSECRET,
    VALIDATIONSECRET,
    ClientTokensCache);

  GenerateRefreshTokenUseCase := TGenerateRefreshTokenUseCase.Create(
    JwtManager,
    SIGNINGSECRET,
    VALIDATIONSECRET);

  ServerTokensCache := TSingleInstanceServerTokensCache.Create;

  UseCase := TRefreshTokenUseCase.Create(
    JwtManager,
    GenerateAccessTokenUseCase,
    GenerateRefreshTokenUseCase,
    VALIDATIONSECRET,
    ServerTokensCache);

  Resource := TRefreshTokenV1ApiServerController.Create(

    UseCase);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute('', Authorization, RefreshToken);
    end,
    EApiServer400);

  AuthorizationV1ApiClient.Received(Times.Never).GetRole;
end;

initialization
  TDUnitX.RegisterTestFixture(TAuthenticationServiceIntegrationApiServersRefreshTokenV1Tests);

end.
