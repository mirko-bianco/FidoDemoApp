unit UsersService.DI.Registration;

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
  Fido.KVStore.Intf,
  Fido.KVStore.JSON,
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
  Fido.EventsDriven.Listener.PubSub,
  Fido.EventsDriven.Listener.Intf,
  Fido.EventsDriven.Publisher.Intf,
  Fido.EventsDriven.Publisher,
  Fido.EventsDriven.Consumer.PubSub.Intf,
  Fido.EventsDriven.Producer.Intf,
  Fido.EventsDriven.Subscriber.Intf,
  Fido.EventsDriven.Subscriber,
  Fido.JWT.Manager.Intf,
  Fido.JWT.Manager,

  Fido.Redis.Client.Intf,
  Fido.Redis.Client,
  Fido.Redis.KVStore,
  Fido.Redis.EventsDriven.Consumer.QueuePubSub,
  Fido.Redis.EventsDriven.Producer.QueuePubSub,

  FidoApp.Constants,
  FidoApp.Types,
  FidoApp.Utils,
  FidoApp.DI.Registration,
  FidoApp.Presentation.Controllers.ApiServers.Health,
  FidoApp.Domain.Usecases.RefreshToken.Intf,
  FidoApp.Domain.Usecases.RefreshToken,
  FidoApp.Persistence.Repositories.DatabaseMigrations,

  UsersService.Constants,
  UsersService.Presentation.Controllers.ApiServers.GetAll.V1,
  UsersService.Presentation.Consumers.RemoveUser,
  UsersService.Presentation.Consumers.AddUser,
  UsersService.Domain.UseCases.Remove.DI.Registration,
  UsersService.Domain.UseCases.Add.DI.Registration,
  UsersService.Domain.UseCases.GetAll.DI.Registration,
  UsersService.Persistence.Gateways.DI.Registration,
  UsersService.Persistence.Repositories.DI.Registration,
  UsersService.Persistence.Db.DI.Registration;

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
  IniFile: IShared<TMemIniFile>;
  FireDacDatabaseParams: IShared<TStringList>;
  RedisHost: string;
  RedisPort: Integer;
begin
  IniFile := Shared.Make(TMemIniFile.Create(Utils.Files.GetIniFilename));
  Registration.RegisterFramework(Container);

  Fido.Consul.DI.Registration.Register(Container, IniFile);
  Container.RegisterType<ILogAppender>(
    function: ILogAppender
    begin
      Result := TPermanentFileLogAppender.Create(IniFile.ReadString('Log', 'Filename', Utils.Files.GetLogFilename));
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

  Container.RegisterType<IJWTManager, TJWTManager>;

  Container.RegisterType<IApiServer>(
    function: IApiServer
    var
      Server: IApiServer;
    begin
      if IniFile.ReadString('Server', 'Type', 'Brook') = 'Indy' then
        Server := TIndyApiServer.Create(
          IniFile.ReadInteger('Server', 'Port', 8080),
          IniFile.ReadInteger('IndyServer', 'MaxConnections', 50),
          TNullWebServer.Create,
          TSSLCertData.CreateEmpty)
      else
        Server := TBrookApiServer.Create(
          IniFile.ReadInteger('Server', 'Port', 8080),
          IniFile.ReadInteger('BrookServer', 'ConnectionLimit', 50),
          IniFile.ReadBool('BrookServer', 'Threaded', True),
          IniFile.ReadInteger('BrookServer', 'ThreadPoolSize', 0),
          mtJson,
          TNullWebServer.Create,
          TSSLCertData.CreateEmpty);

      Result := TConsulAwareApiServer.Create(
        Server,
        Container.Resolve<IConsulService>,
        IniFile.ReadString('Server', 'ServiceName', 'UsersService'),
        Constants.TIMEOUT);
    end);

  RedisHost := ConsulKVStore.Get('redis.host', Constants.TIMEOUT);
  RedisPort := JSONKVStore.Get<Integer>(ConsulKVStore, 'redis.port', Constants.TIMEOUT);

  Container.RegisterType<IRedisClient>(
    function: IRedisClient
    begin
      Result := TRedisClient.Create(RedisHost, RedisPort);
      Result.Connect;
    end);

  Container.RegisterType<IFidoRedisClient, TFidoRedisClient>;
  Container.RegisterFactory<IFidoRedisClientFactory>;

  UsersService.Persistence.Db.DI.Registration.DIRegistration(Container);
  UsersService.Persistence.Gateways.DI.Registration.DIRegistration(Container);
  UsersService.Persistence.Repositories.DI.Registration.DIRegistration(Container);
  UsersService.Domain.UseCases.Add.DI.Registration.DIRegistration(Container);
  UsersService.Domain.UseCases.Remove.DI.Registration.DIRegistration(Container);
  UsersService.Domain.UseCases.GetAll.DI.Registration.DIRegistration(Container);

  Container.RegisterType<THealthApiServerController>;

  Container.RegisterType<IPubSubEventsDrivenConsumer<string>, TRedisQueuePubSubEventsDrivenConsumer>;
  Container.RegisterFactory<IPubSubEventsDrivenConsumerFactory<string>>;
  Container.RegisterType<IEventsDrivenProducer<string>, TRedisQueuePubSubEventsDrivenProducer>;
  Container.RegisterFactory<IEventsDrivenProducerFactory<string>>;
  Container.RegisterType<IEventsDrivenListener, TPubSubEventsDrivenListener<string>>;
  Container.RegisterType<IEventsDrivenPublisher<string>, TEventsDrivenPublisher<string>>;
  Container.RegisterType<IEventsDrivenSubscriber, TEventsDrivenSubscriber>;

  Container.RegisterType<TAddUserConsumerController>;
  Container.RegisterType<TRemoveUserConsumerController>;
  Container.RegisterType<TGetAllV1ApiServerController>;

  Container.Build;
end;

end.
