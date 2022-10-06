unit FidoApp.Persistence.ApiClients.Configuration.Tokens.Tests;

interface

uses
  System.SysUtils,

  DUnitX.TestFramework,

  Spring.Mocking,

  Fido.Testing.Mock.Utils,

  FidoApp.Domain.ClientTokensCache,
  FidoApp.Domain.ClientTokensCache.Intf,
  FidoApp.Persistence.ApiClients.Configuration.Tokens;

type
  [TestFixture]
  TTokensAwareClientVirtualApiConfigurationTests = class
  public
    [Test]
    procedure SettingValuesTest;

    [Test]
    procedure ResettingOnlyAuthorizationDoesNotChangeTheTokens;

    [Test]
    procedure ResettingOnlyRefreshTokenDoesNotChangeTheTokens;

    [Test]
    procedure ResettingBothValuesChangesTheTokens;
  end;

implementation

{ TTokensAwareClientVirtualApiConfigurationTests }

procedure TTokensAwareClientVirtualApiConfigurationTests.ResettingOnlyAuthorizationDoesNotChangeTheTokens;
var
  Cache: IClientTokensCache;
  Configuration: ITokensAwareClientVirtualApiConfiguration;
  OriginalAuthorization: string;
  OriginalRefreshToken: string;
  NewAuthorization: string;
  BaseUrl: string;
begin
  Cache := TClientTokensCache.Create;

  BaseUrl := MockUtils.SomeString;

  Configuration := TTokensAwareClientVirtualApiConfiguration.Create(BaseUrl, True, False, Cache);

  OriginalAuthorization := MockUtils.SomeString;
  OriginalRefreshToken := MockUtils.SomeString;

  Configuration.SetAuthorization(OriginalAuthorization);
  Configuration.SetRefreshToken(OriginalRefreshToken);

  NewAuthorization := MockUtils.SomeString;

  Configuration.SetAuthorization(NewAuthorization);

  Assert.AreEqual(Format('Bearer %s', [OriginalAuthorization]), Configuration.GetAuthorization, 'Configuration.GetAuthorization');
  Assert.AreEqual(OriginalRefreshToken, Configuration.GetRefreshToken, 'Configuration.GetRefreshToken');
end;

procedure TTokensAwareClientVirtualApiConfigurationTests.ResettingOnlyRefreshTokenDoesNotChangeTheTokens;
var
  Cache: IClientTokensCache;
  Configuration: ITokensAwareClientVirtualApiConfiguration;
  OriginalAuthorization: string;
  OriginalRefreshToken: string;
  NewRefreshToken: string;
  BaseUrl: string;
begin
  Cache := TClientTokensCache.Create;

  BaseUrl := MockUtils.SomeString;

  Configuration := TTokensAwareClientVirtualApiConfiguration.Create(BaseUrl, True, False, Cache);

  OriginalAuthorization := MockUtils.SomeString;
  OriginalRefreshToken := MockUtils.SomeString;

  Configuration.SetAuthorization(OriginalAuthorization);
  Configuration.SetRefreshToken(OriginalRefreshToken);

  NewRefreshToken := MockUtils.SomeString;

  Configuration.SetRefreshToken(NewRefreshToken);

  Assert.AreEqual(Format('Bearer %s', [OriginalAuthorization]), Configuration.GetAuthorization, 'Configuration.GetAuthorization');
  Assert.AreEqual(OriginalRefreshToken, Configuration.GetRefreshToken, 'Configuration.GetRefreshToken');
end;

procedure TTokensAwareClientVirtualApiConfigurationTests.ResettingBothValuesChangesTheTokens;
var
  Cache: IClientTokensCache;
  Configuration: ITokensAwareClientVirtualApiConfiguration;
  OriginalAuthorization: string;
  OriginalRefreshToken: string;
  NewAuthorization: string;
  NewRefreshToken: string;
  BaseUrl: string;
begin
  Cache := TClientTokensCache.Create;

  BaseUrl := MockUtils.SomeString;

  Configuration := TTokensAwareClientVirtualApiConfiguration.Create(BaseUrl, True, False, Cache);

  OriginalAuthorization := MockUtils.SomeString;
  OriginalRefreshToken := MockUtils.SomeString;

  Configuration.SetAuthorization(OriginalAuthorization);
  Configuration.SetRefreshToken(OriginalRefreshToken);

  NewAuthorization := MockUtils.SomeString;
  NewRefreshToken := MockUtils.SomeString;

  Configuration.SetAuthorization(NewAuthorization);
  Configuration.SetRefreshToken(NewRefreshToken);

  Assert.AreEqual(Format('Bearer %s', [NewAuthorization]), Configuration.GetAuthorization, 'Configuration.GetAuthorization');
  Assert.AreEqual(NewRefreshToken, Configuration.GetRefreshToken, 'Configuration.GetRefreshToken');
end;

procedure TTokensAwareClientVirtualApiConfigurationTests.SettingValuesTest;
var
  Cache: IClientTokensCache;
  Configuration: ITokensAwareClientVirtualApiConfiguration;
  Authorization: string;
  RefreshToken: string;
  BaseUrl: string;
begin
  Cache := TClientTokensCache.Create;

  BaseUrl := MockUtils.SomeString;

  Configuration := TTokensAwareClientVirtualApiConfiguration.Create(BaseUrl, True, False, Cache);

  Authorization := MockUtils.SomeString;
  RefreshToken := MockUtils.SomeString;

  Configuration.SetAuthorization(Authorization);
  Configuration.SetRefreshToken(RefreshToken);

  Assert.AreEqual(Format('Bearer %s', [Authorization]), Configuration.GetAuthorization, 'Configuration.GetAuthorization');
  Assert.AreEqual(RefreshToken, Configuration.GetRefreshToken, 'Configuration.GetRefreshToken');
  Assert.AreEqual(BaseUrl, Configuration.BaseUrl, 'Configuration.BaseUrl');
  Assert.IsTrue(Configuration.Active, 'Configuration.Active');
  Assert.IsFalse(Configuration.LiveEnvironment, 'Configuration.LiveEnvironment');
end;

initialization
 TDUnitX.RegisterTestFixture(TTokensAwareClientVirtualApiConfigurationTests);

end.
