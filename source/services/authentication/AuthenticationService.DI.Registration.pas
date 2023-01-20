unit AuthenticationService.DI.Registration;

interface

uses
  System.Classes,
  System.SysUtils,
  System.IniFiles,

  FireDAC.Phys,
  FireDAC.Stan.Async,
  FireDAC.Stan.Intf,
  FireDac.Stan.Def,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef,
  FireDAC.UI.Intf,
  FireDAC.ConsoleUI.Wait,
  FireDAC.Comp.UI,
  FireDAC.Dapt,

  Spring,
  Spring.Container,
  Spring.Logging,
  Spring.Logging.Loggers,
  Spring.Logging.Controller,
  Spring.Logging.Appenders,

  Redis.Commons,
  Redis.NetLib.Indy,
  Redis.Client,

  Fido.Registration,
  Fido.Types,
  Fido.Containers,
  Fido.Db.Connections.FireDac,
  Fido.Db.Connections.FireDac.PerThread,
  Fido.StatementExecutor.Intf,
  Fido.Db.StatementExecutor.FireDac,
  Fido.Http.Types,
  Fido.Web.Server.Null,
  Fido.Api.Server.Intf,
  Fido.Api.Server.Brook,
  Fido.Api.Server.Indy,
  Fido.JWT.Manager.Intf,
  Fido.JWT.Manager,
  Fido.KVStore.Intf,
  Fido.Testing.Mock.Utils,
  Fido.Db.Migrations.Model.Intf,
  Fido.Db.Migrations.Model,
  Fido.Db.ScriptRunner.Intf,
  Fido.Db.ScriptRunner.FireDac,
  Fido.Db.Migrations.Repository.Intf,
  Fido.Api.Client.VirtualApi.json,
  Fido.Logging.Appenders.PermanentFile,
  Fido.Consul.DI.Registration,
  Fido.Api.Server.Consul,
  Fido.Consul.Service.Intf,
  Fido.KVStore.JSON,
  Fido.EventsDriven.Listener.PubSub,
  Fido.EventsDriven.Listener.Intf,
  Fido.EventsDriven.Publisher.Intf,
  Fido.EventsDriven.Publisher,
  Fido.EventsDriven.Consumer.PubSub.Intf,
  Fido.EventsDriven.Producer.Intf,
  Fido.EventsDriven.Subscriber.Intf,
  Fido.EventsDriven.Subscriber,

  Fido.Redis.Client.Intf,
  Fido.Redis.Client,
  Fido.Redis.KVStore,
  Fido.Redis.EventsDriven.Consumer.QueuePubSub,
  Fido.Redis.EventsDriven.Producer.QueuePubSub,

  FidoApp.Types,
  FidoApp.Utils,
  FidoApp.Constants,
  FidoApp.DI.Registration,
  FidoApp.Persistence.Repositories.DatabaseMigrations,
  FidoApp.Presentation.Controllers.ApiServers.Health,
  FidoApp.Domain.Usecases.RefreshToken.Intf,
  FidoApp.Domain.Usecases.RefreshToken,

  AuthenticationService.Constants,
  AuthenticationService.Persistence.Db.DI.Registration,
  AuthenticationService.Persistence.Gateways.DI.Registration,
  AuthenticationService.Persistence.Repositories.DI.Registration,
  AuthenticationService.Presentation.Controllers.ApiServers.Login.V1,
  AuthenticationService.Presentation.Controllers.ApiServers.Signup.V1,
  AuthenticationService.Presentation.Controllers.ApiServers.RefreshToken.V1,
  AuthenticationService.Presentation.Controllers.ApiServers.ChangeActiveStatus.V1,
  AuthenticationService.Presentation.Consumers.ActivateUser,
  AuthenticationService.Presentation.Consumers.CancelSignup,
  AuthenticationService.Domain.UseCases.Login.DI.Registration,
  AuthenticationService.Domain.UseCases.GenerateAccessToken.DI.Registration,
  AuthenticationService.Domain.UseCases.GenerateRefreshToken.DI.Registration,
  AuthenticationService.Domain.UseCases.RefreshToken.DI.Registration,
  AuthenticationService.Domain.UseCases.Signup.DI.Registration,
  AuthenticationService.Domain.UseCases.AddRoleToToken.DI.Registration,
  AuthenticationService.Domain.UseCases.ChangeActiveStatus.DI.Registration,
  AuthenticationService.Domain.UseCases.Remove.DI.Registration,
  AuthenticationService.Domain.TokensCache.Intf,
  AuthenticationService.Domain.TokensCache.KVStore;

procedure DIRegistration(const Container: TContainer);
function InitializeFireDacCursor: TFDGUIxWaitCursor;

implementation

function InitializeFireDacCursor: TFDGUIxWaitCursor;
var
  DGUIxWaitCursor: TFDGUIxWaitCursor;
begin
  DGUIxWaitCursor := TFDGUIxWaitCursor.Create(nil);
  DGUIxWaitCursor.Provider := 'Console';
  DGUIxWaitCursor.ScreenCursor := gcrNone;

  Result := DGUIxWaitCursor;
end;

procedure DIRegistration(const Container: TContainer);
var
  ConsulKVStore: IKVStore;
  PublicKeyContent: string;
  PrivateKeyContent: string;
  IniFile: IShared<TMemIniFile>;
  FireDacDatabaseParams: IShared<TStringList>;
  LogFileName: string;
begin
  IniFile := Shared.Make(TMemIniFile.Create(Utils.Files.GetIniFilename));
  Registration.RegisterFramework(Container);

  Fido.Consul.DI.Registration.Register(Container, IniFile);
  LogFilename := IniFile.ReadString('Log', 'Filename', Utils.Files.GetLogFilename);
  Container.RegisterType<ILogAppender>(
    function: ILogAppender
    begin
      Result := TPermanentFileLogAppender.Create(LogFilename);
    end);

  Container.RegisterType<ILogger>(
    function: ILogger
    begin
      Result := TLogger.Create(TLoggerController.Create([Container.Resolve<ILogAppender>]));
    end).AsSingleton;
  Container.Build;
  ConsulKVStore := Container.Resolve<IKVStore>;

  FireDacDatabaseParams := Shared.Make(TStringList.Create);
  FireDacDatabaseParams.Values['DriverID'] := ConsulKVStore.Get('database.driverid', Constants.TIMEOUT);
  FireDacDatabaseParams.Values['User_Name'] := ConsulKVStore.Get('database.username', Constants.TIMEOUT);
  FireDacDatabaseParams.Values['Password'] := ConsulKVStore.Get('database.password', Constants.TIMEOUT);
  FireDacDatabaseParams.Values['Server'] := ConsulKVStore.Get('database.server', Constants.TIMEOUT);
  FireDacDatabaseParams.Values['Port'] := ConsulKVStore.Get('database.port', Constants.TIMEOUT);

  PublicKeyContent := ConsulKVStore.Get('public.key', Constants.TIMEOUT);
  PrivateKeyContent := ConsulKVStore.Get('private.key', Constants.TIMEOUT);

  Container.RegisterType<TFireDacConnections>(
    function: TFireDacConnections
    begin
      Result := TFireDacPerThreadConnections.Create(FireDacDatabaseParams);
    end).AsSingleton;

  Container.RegisterType<IStatementExecutor, TFireDacStatementExecutor>;

  Container.RegisterType<IDatabaseScriptRunner, TFireDacDatabaseScriptRunner>;
  Container.RegisterType<IDatabaseMigrationsRepository>(
    function: IDatabaseMigrationsRepository
    begin
      Result := TDatabaseMigrationsRepository.Create(
        Container.Resolve<TFireDacConnections>,
        DATABASENAME);
    end);
  Container.RegisterType<IDatabaseMigrationsModel>(
    function: IDatabaseMigrationsModel
    begin
      Result := TDatabaseMigrationsModel.Create(
        Container.Resolve<IDatabaseScriptRunner>,
        Container.Resolve<IDatabaseMigrationsRepository>,
        'DbMigrations');
    end);

  Container.RegisterType<IApiServer>(
    function: IApiServer
    var
      Server: IApiServer;
    begin
      if IniFile.ReadString('Server', 'Type', 'Brook') = 'Indy' then
        Server := TIndyApiServer.Create(
          IniFile.ReadInteger('Server', 'Port', 8080),
          IniFile.ReadInteger('IndyServer', 'MaxConnections', 50),
          TSSLCertData.CreateEmpty)
      else
        Server := TBrookApiServer.Create(
          IniFile.ReadInteger('Server', 'Port', 8080),
          IniFile.ReadInteger('BrookServer', 'ConnectionLimit', 50),
          IniFile.ReadBool('BrookServer', 'Threaded', True),
          IniFile.ReadInteger('BrookServer', 'ThreadPoolSize', 0),
          mtJson,
          TSSLCertData.CreateEmpty);

      Result := TConsulAwareApiServer.Create(
        Server,
        Container.Resolve<IConsulService>,
        IniFile.ReadString('Server', 'ServiceName', 'AuthenticationService'),
        Constants.TIMEOUT);
    end);

  Container.RegisterType<IJWTManager, TJWTManager>;

  FidoApp.DI.Registration.RegisterAuthorizationApiV1(Container, ConsulKVStore);

  Container.RegisterType<IRedisClient>(
    function: IRedisClient
    begin
      Result := TRedisClient.Create(
        ConsulKVStore.Get('redis.host', Constants.TIMEOUT),
        JSONKVStore.Get<Integer>(ConsulKVStore, 'redis.port', Constants.TIMEOUT));
      Result.Connect;
    end);

  Container.RegisterType<IFidoRedisClient, TFidoRedisClient>;
  Container.RegisterFactory<IFidoRedisClientFactory>;

  Container.RegisterType<IServerTokensCache>(
    function: IServerTokensCache
    begin
      Result := TKVStoreServerTokensCache.Create(
        TRedisKVStore.Create(
          Container.Resolve<IFidoRedisClient>,
          'TOKENSCACHE::'));
    end).AsSingletonPerThread;

  AuthenticationService.Persistence.Db.DI.Registration.DIRegistration(Container);
  AuthenticationService.Persistence.Gateways.DI.Registration.DIRegistration(Container);
  AuthenticationService.Persistence.Repositories.DI.Registration.DIRegistration(Container);
  AuthenticationService.Domain.UseCases.Login.DI.Registration.DIRegistration(Container);
  AuthenticationService.Domain.UseCases.GenerateAccessToken.DI.Registration.DIRegistration(Container, PublicKeyContent, PrivateKeyContent);
  AuthenticationService.Domain.UseCases.GenerateRefreshToken.DI.Registration.DIRegistration(Container, PublicKeyContent, PrivateKeyContent);
  AuthenticationService.Domain.UseCases.RefreshToken.DI.Registration.DIRegistration(Container, PublicKeyContent);
  AuthenticationService.Domain.UseCases.Signup.DI.Registration.DIRegistration(Container);
  AuthenticationService.Domain.UseCases.AddRoleToToken.DI.Registration.DIRegistration(Container);
  AuthenticationService.Domain.UseCases.ChangeActiveStatus.DI.Registration.DIRegistration(Container);
  AuthenticationService.Domain.UseCases.Remove.DI.Registration.DIRegistration(Container);

  FidoApp.DI.Registration.RegisterTokensCache(Container);

  Container.RegisterType<THealthApiServerController>;
  Container.RegisterType<TLoginV1ApiServerController>;
  Container.RegisterType<TSignupV1ApiServerController>;
  Container.RegisterType<TRefreshTokenV1ApiServerController>;
  Container.RegisterType<TChangeActiveStatusV1ApiServerController>;

  Container.RegisterType<IPubSubEventsDrivenConsumer<string>, TRedisQueuePubSubEventsDrivenConsumer>;
  Container.RegisterFactory<IPubSubEventsDrivenConsumerFactory<string>>;
  Container.RegisterType<IEventsDrivenProducer<string>, TRedisQueuePubSubEventsDrivenProducer>;
  Container.RegisterFactory<IEventsDrivenProducerFactory<string>>;
  Container.RegisterType<IEventsDrivenListener, TPubSubEventsDrivenListener<string>>;
  Container.RegisterType<IEventsDrivenPublisher<string>, TEventsDrivenPublisher<string>>;
  Container.RegisterType<IEventsDrivenSubscriber, TEventsDrivenSubscriber>;

  Container.RegisterType<TActivateUserConsumerController>;
  Container.RegisterType<TCancelSignupConsumerController>;

  Container.Build;
end;

end.
