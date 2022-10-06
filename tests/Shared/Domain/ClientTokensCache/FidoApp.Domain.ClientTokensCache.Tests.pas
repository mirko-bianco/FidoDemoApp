unit FidoApp.Domain.ClientTokensCache.Tests;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.NetEncoding,

  DUnitX.TestFramework,

  Spring,
  Spring.Times,
  Spring.Collections,
  Spring.Mocking,

  Fido.Types,
  Fido.DesignPatterns.Observer.Intf,
  Fido.DesignPatterns.Observer.Notification.Intf,
  Fido.Testing.Mock.Utils,
  Fido.JSON.Marshalling,

  FidoApp.Types,
  FidoApp.Messages,
  FidoApp.Domain.ClientTokensCache,
  FidoApp.Domain.ClientTokensCache.Intf,
  FidoApp.Domain.UseCases.RefreshToken.Intf;

type
  EClienTClientTokensCacheTests = class(Exception);

  [TestFixture]
  TClienTClientTokensCacheTests = class
  public
    [Test]
    procedure EmptyCacheDoesNotBroadcastMessages;

    [Test]
    procedure SetTokenBroadcastsToObserver;
  end;

implementation

Type
  TObserver = class(TInterfacedObject, IObserver)
  private Type
    TOnNotify = reference to procedure(const Sender: IInterface; const Notification: INotification);
  private
    FOnNotify: TOnNotify;
  public
    constructor Create(const OnNotify: TOnNotify);

    procedure Notify(const Sender: IInterface; const Notification: INotification);
  end;

{ TClientTokensCacheTests }

procedure TClienTClientTokensCacheTests.EmptyCacheDoesNotBroadcastMessages;
var
  TokensCache: IClientTokensCache;
begin
  TokensCache := TClientTokensCache.Create;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.IsNull(TokensCache.Tokens, 'TokensCache.Tokens');
    end);

  TokensCache := nil;
end;

procedure TClienTClientTokensCacheTests.SetTokenBroadcastsToObserver;
var
  TokensCache: IClientTokensCache;
  Observer: IObserver;
  LoggedCount: Integer;
  Tokens: ITokens;
begin
  LoggedCount := 0;
  Tokens := JSONUnmarshaller.To<ITokens>(Format('{"AccessToken": "%s", "RefreshToken": "%s"}', [MockUtils.SomeString, MockUtils.SomeString]));

  TokensCache := TClientTokensCache.Create;

  Observer := TObserver.Create(
    procedure(const Sender: IInterface; const Notification: INotification)
    begin
      if Notification.GetDescription = LOGGED_MESSAGE then
        Inc(LoggedCount);
    end);

  TokensCache.RegisterObserver(Observer);

  TokensCache.SetTokens(Tokens);

  Assert.IsNotEmpty(TokensCache.Tokens, 'TokensCache.Tokens');
  Assert.AreEqual(1, LoggedCount, 'LoggedCount');
  Assert.AreEqual(Tokens.AccessToken, TokensCache.Tokens.AccessToken, 'TokensCache.Tokens.AccessToken');
  Assert.AreEqual(Tokens.RefreshToken, TokensCache.Tokens.RefreshToken, 'TokensCache.Tokens.RefreshToken');

  TokensCache.UnregisterObserver(Observer);

  TokensCache := nil;
end;

{ TObserver }

constructor TObserver.Create(const OnNotify: TOnNotify);
begin
  FOnNotify := OnNotify;
end;

procedure TObserver.Notify(const Sender: IInterface; const Notification: INotification);
begin
  FOnNotify(Sender, Notification);
end;

initialization
 TDUnitX.RegisterTestFixture(TClienTClientTokensCacheTests);

end.
