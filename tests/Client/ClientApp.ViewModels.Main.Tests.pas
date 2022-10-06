unit ClientApp.ViewModels.Main.Tests;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Threading,
  System.Rtti,

  DUnitX.TestFramework,

  Spring,
  Spring.Times,
  Spring.Collections,
  Spring.Mocking,
  Spring.Logging,

  Fido.Types,
  Fido.Functional,
  Fido.Testing.Mock.Utils,
  Fido.Api.Client.Exception,
  Fido.JSON.Marshalling,
  Fido.EventsDriven.Subscriber.Intf,
  Fido.DesignPatterns.Observer.Intf,
  Fido.DesignPatterns.Observer.Notification,

  FidoApp.Types,
  FidoApp.Messages,
  FidoApp.Domain.ClientTokensCache.Intf,
  FidoApp.Domain.ClientTokensCache,

  ClientApp.Types,
  ClientApp.Messages,
  ClientApp.Models.Domain.UseCases.ShowLoginView.Intf,
  ClientApp.Models.Domain.UseCases.ShowLoginView,
  ClientApp.ViewModels.Main.Intf,
  ClientApp.ViewModels.Main,
  ClientApp.Views.Login.Intf;

type
  [TestFixture]
  TMainViewModelTests = class
  public
    [Test]
    procedure PressLogButtonResetsTheTokenWhenATokenExistsAlready;

    [Test]
    procedure PressLogButtonShowsTheLoginViewWhenATokenDoesNotExist;

    [Test]
    procedure OnCloseLoginViewChangedBusyStatus;

    [Test]
    procedure NotifyTriggersLOGGED_MESSAGEEvent;

    [Test]
    procedure NotifyTriggersTOKEN_CHANGED_MESSAGEEvent;
  end;

implementation

{ TMainViewModelTests }

procedure TMainViewModelTests.NotifyTriggersLOGGED_MESSAGEEvent;
var
  MainViewModel: TMainViewModel;

  Subscriber: Mock<IEventsDrivenSubscriber>;
  Publisher: Mock<IEventsDrivenPublisher>;
  Logger: Mock<ILogger>;
  TokensCache: IClientTokensCache;
  ShowLoginViewUseCase: IShowLoginViewUseCase;
  LoginView: Mock<ILoginView>;
begin
  Subscriber := Mock<IEventsDrivenSubscriber>.Create;
  Publisher := Mock<IEventsDrivenPublisher>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('MainViewModel', LOGGED_MESSAGE, []);
  Logger := Mock<ILogger>.Create;

  TokensCache := TClientTokensCache.Create;

  LoginView := Mock<ILoginView>.Create;

  ShowLoginViewUseCase := TShowLoginViewUseCase.Create(
    Logger,
    function: ILoginView
    begin
      Result := LoginView;
    end);

  MainViewModel := TMainViewModel.Create(Subscriber, Publisher, TokensCache, ShowLoginViewUseCase);
  Assert.WillNotRaiseAny(
    procedure
    var
      Observer: IObserver;
    begin
      if Supports(MainViewModel, IObserver, Observer) then
        Observer.Notify(nil, TNotification.Create(nil, LOGGED_MESSAGE, TValue.From<TArray<TValue>>([])));
    end);

  Publisher.Received(Times.Once).Trigger('MainViewModel', LOGGED_MESSAGE, []);
end;

procedure TMainViewModelTests.NotifyTriggersTOKEN_CHANGED_MESSAGEEvent;
var
  MainViewModel: IMainViewModel;

  Subscriber: Mock<IEventsDrivenSubscriber>;
  Publisher: Mock<IEventsDrivenPublisher>;
  Logger: Mock<ILogger>;
  TokensCache: IClientTokensCache;
  ShowLoginViewUseCase: IShowLoginViewUseCase;
  LoginView: Mock<ILoginView>;
begin
  Subscriber := Mock<IEventsDrivenSubscriber>.Create;
  Publisher := Mock<IEventsDrivenPublisher>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('MainViewModel', TOKEN_CHANGED_MESSAGE, []);
  Logger := Mock<ILogger>.Create;

  TokensCache := TClientTokensCache.Create;

  LoginView := Mock<ILoginView>.Create;

  ShowLoginViewUseCase := TShowLoginViewUseCase.Create(
    Logger,
    function: ILoginView
    begin
      Result := LoginView;
    end);

  MainViewModel := TMainViewModel.Create(Subscriber, Publisher, TokensCache, ShowLoginViewUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      (MainViewModel as IObserver).Notify(nil, TNotification.Create(nil, TOKEN_CHANGED_MESSAGE, TValue.From<TArray<TValue>>([])));
    end);

  Publisher.Received(Times.Once).Trigger('MainViewModel', TOKEN_CHANGED_MESSAGE, []);
end;

procedure TMainViewModelTests.OnCloseLoginViewChangedBusyStatus;
var
  MainViewModel: IMainViewModel;

  Subscriber: Mock<IEventsDrivenSubscriber>;
  Publisher: Mock<IEventsDrivenPublisher>;
  Logger: Mock<ILogger>;
  TokensCache: IClientTokensCache;
  ShowLoginViewUseCase: IShowLoginViewUseCase;
  LoginView: Mock<ILoginView>;
begin
  Subscriber := Mock<IEventsDrivenSubscriber>.Create;
  Publisher := Mock<IEventsDrivenPublisher>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('MainViewModel', VIEW_BUSY_MESSAGE, [False]);
  Logger := Mock<ILogger>.Create;

  TokensCache := TClientTokensCache.Create;

  LoginView := Mock<ILoginView>.Create;

  ShowLoginViewUseCase := TShowLoginViewUseCase.Create(
    Logger,
    function: ILoginView
    begin
      Result := LoginView;
    end);

  MainViewModel := TMainViewModel.Create(Subscriber, Publisher, TokensCache, ShowLoginViewUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      MainViewModel.OnCloseLoginView;
    end);

  Publisher.Received(Times.Once).Trigger('MainViewModel', VIEW_BUSY_MESSAGE, [False]);
end;

procedure TMainViewModelTests.PressLogButtonResetsTheTokenWhenATokenExistsAlready;
var
  MainViewModel: IMainViewModel;

  Subscriber: IEventsDrivenSubscriber;
  Publisher: Mock<IEventsDrivenPublisher>;
  Logger: Mock<ILogger>;
  TokensCache: Mock<IClientTokensCache>;
  ShowLoginViewUseCase: IShowLoginViewUseCase;
  LoginView: Mock<ILoginView>;
  Tokens: ITokens;
begin
  Subscriber := Mock<IEventsDrivenSubscriber>.Create;
  Publisher := Mock<IEventsDrivenPublisher>.Create;
  Logger := Mock<ILogger>.Create;

  Tokens := JSONUnmarshaller.To<ITokens>(Format('{"AccessToken": "%s", "RefreshToken": "%s"}', [MockUtils.SomeString, MockUtils.SomeString]));

  TokensCache := Mock<IClientTokensCache>.Create;
  TokensCache.Setup.Returns<ITokens>(Tokens).When.Tokens;

  LoginView := Mock<ILoginView>.Create;

  ShowLoginViewUseCase := TShowLoginViewUseCase.Create(
    Logger,
    function: ILoginView
    begin
      Result := LoginView;
    end);

  MainViewModel := TMainViewModel.Create(Subscriber, Publisher, TokensCache, ShowLoginViewUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      MainViewModel.PressLogButton;
    end);

  TokensCache.Received(Times.Once).SetTokens(nil);
  TokensCache.Received(Times.Never).SetTokens(Arg.IsNotIn<ITokens>([nil]));
  LoginView.Received(Times.Never).Show;
end;

procedure TMainViewModelTests.PressLogButtonShowsTheLoginViewWhenATokenDoesNotExist;
var
  MainViewModel: IMainViewModel;

Subscriber: Mock<IEventsDrivenSubscriber>;
  Publisher: Mock<IEventsDrivenPublisher>;
  Logger: Mock<ILogger>;
  TokensCache: IClientTokensCache;
  ShowLoginViewUseCase: IShowLoginViewUseCase;
  LoginView: Mock<ILoginView>;
begin
  Subscriber := Mock<IEventsDrivenSubscriber>.Create;
  Publisher := Mock<IEventsDrivenPublisher>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('MainViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('MainViewModel', VIEW_BUSY_MESSAGE, [False]);

  Logger := Mock<ILogger>.Create;

  TokensCache := TClientTokensCache.Create;

  LoginView := Mock<ILoginView>.Create;

  ShowLoginViewUseCase := TShowLoginViewUseCase.Create(
    Logger,
    function: ILoginView
    begin
      Result := LoginView;
    end);

  MainViewModel := TMainViewModel.Create(Subscriber, Publisher, TokensCache, ShowLoginViewUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      MainViewModel.PressLogButton;
    end);

  Sleep(30);

  LoginView.Received(Times.Once).Show;
  Publisher.Received(Times.Once).Trigger('MainViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Never).Trigger('MainViewModel', VIEW_BUSY_MESSAGE, [False]);
end;

initialization
  TDUnitX.RegisterTestFixture(TMainViewModelTests);

end.
