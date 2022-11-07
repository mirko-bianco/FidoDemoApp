unit ClientApp.DI;

interface

uses
  System.IniFiles,
  System.Generics.Collections,
  System.Rtti,

  FMX.Forms,

  Spring.Container,
  Spring.Logging,
  Spring.Logging.Loggers,
  Spring.Logging.Controller,
  Spring.Logging.Appenders,

  Fido.Types,
  Fido.Exceptions,
  Fido.DesignPatterns.Observer.Intf,
  Fido.DesignPatterns.Observable.Intf,
  Fido.Logging.Appenders.PermanentFile,
  Fido.JWT.Manager.Intf,
  Fido.JWT.Manager,
  Fido.KVStore.Intf,
  Fido.Consul.DI.Registration,

  Fido.EventsDriven.Listener.Intf,
  Fido.EventsDriven.Subscriber.Intf,
  Fido.EventsDriven.Subscriber,

  FidoApp.Types,
  FidoApp.Constants,
  FidoApp.Utils,
  FidoApp.DI.Registration,
  FidoApp.Domain.ClientTokensCache.Intf,
  FidoApp.Domain.ClientTokensCache,
  FidoApp.Domain.UseCases.RefreshToken.Intf,
  FidoApp.Domain.UseCases.RefreshToken,

  ClientApp.Types,
  ClientApp.Views.Login,
  ClientApp.Views.Login.Intf,
  ClientApp.Views.Main,
  ClientApp.ViewModels.Login.Intf,
  ClientApp.ViewModels.Login,
  ClientApp.ViewModels.Main.Intf,
  ClientApp.ViewModels.Main,
  ClientApp.ViewModels.Users.Intf,
  ClientApp.ViewModels.Users,
  ClientApp.Models.Domain.Usecases.Login.Intf,
  ClientApp.Models.Domain.Usecases.Login,
  ClientApp.Models.Domain.Usecases.ShowLoginView.Intf,
  ClientApp.Models.Domain.Usecases.ShowLoginView,
  ClientApp.Models.Domain.Usecases.Signup.Intf,
  ClientApp.Models.Domain.UseCases.Signup,
  ClientApp.Models.Domain.Usecases.GetAllUsers.Intf,
  ClientApp.Models.Domain.UseCases.GetAllUsers,
  ClientApp.Models.Domain.Repositories.Authentication.Intf,
  ClientApp.Models.Domain.Repositories.Users.Intf,
  ClientApp.Models.Persistence.Repositories.Authentication,
  ClientApp.Models.Persistence.Repositories.Users;

procedure Register(const Application: TApplication; const Container: TContainer; const IniFile: TMemIniFile);

implementation

var
  MainView: TMainView;

procedure Register(const Application: TApplication; const Container: TContainer; const IniFile: TMemIniFile);
var
  KVStore: IKVStore;
begin
  Fido.Consul.DI.Registration.Register(Container, IniFile);
  Container.Build;
  KVStore := Container.Resolve<IKVStore>;

  Container.RegisterType<ILogAppender>(
    function: ILogAppender
    begin
      Result := TPermanentFileLogAppender.Create(IniFile.ReadString('Log', 'Filename', Utils.Files.GetLogFilename), 'yyyy-mm-dd hh:nn:ss:zzz');
    end);

  Container.RegisterType<ILogger>(
    function: ILogger
    begin
      Result := TLogger.Create(TLoggerController.Create([Container.Resolve<ILogAppender>]));
    end).AsSingleton;
  Container.RegisterType<IJwtManager, TJwtManager>;
  FidoApp.DI.Registration.RegisterTokensCache(Container);
  FidoApp.DI.Registration.RegisterAuthenticationApiV1(Container, KVStore);

  Container.RegisterType<IPubSubEventsDrivenBroker, TMemoryPubSubEventsDrivenBroker>.AsSingleton;
  Container.RegisterType<IPubSubEventsDrivenConsumer, TMemoryPubSubEventsDrivenConsumer>;
  Container.RegisterFactory<IPubSubEventsDrivenConsumerFactory>;
  Container.RegisterType<IEventsDrivenProducer, TMemoryPubSubEventsDrivenProducer>;
  Container.RegisterFactory<IEventsDrivenProducerFactory>;
  Container.RegisterType<IEventsDrivenListener, TPubSubEventsDrivenListener>;
  Container.RegisterType<IEventsDrivenPublisher, TEventsDrivenPublisher>;
  Container.RegisterType<IEventsDrivenSubscriber, TEventsDrivenSubscriber>;

  Container.RegisterType<IAuthenticationRepository, TAuthenticationRepository>;
  Container.RegisterType<IUsersRepository, TUsersRepository>;
  Container.RegisterType<ILoginUseCase, TLoginUseCase>;
  Container.RegisterType<ISignupUseCase, TSignupUseCase>;
  Container.RegisterType<IShowLoginViewUseCase, TShowLoginViewUseCase>;
  Container.RegisterType<IRefreshTokenUseCase, TRefreshTokenUseCase>;
  Container.RegisterType<IGetAllUsersUseCase, TGetAllUsersUseCase>;
  Container.RegisterType<ILoginViewModel, TLoginViewModel>;
  Container.RegisterType<ILoginView, TLoginView>;
  Container.RegisterType<IUsersViewModel, TUsersViewModel>;
  Container.RegisterType<IMainViewModel, TMainViewModel>;
  Container.RegisterType<TMainView, TMainView>(
    function: TMainView
    begin
      if Assigned(MainView) then
        Exit(MainView);

      Application.CreateForm(TMainView, MainView);
      Application.RealCreateForms;

      MainView.Subscriber := Container.Resolve<IEventsDrivenSubscriber>;
      MainView.ViewModel := Container.Resolve<IMainViewModel>;

      Result := MainView;
    end);

  Container.Build;
end;

end.
