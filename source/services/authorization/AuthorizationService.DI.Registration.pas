unit AuthorizationService.DI.Registration;

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

  Fido.Registration,
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
  Fido.Testing.Mock.Utils,
  Fido.Db.Migrations.Model.Intf,
  Fido.Db.Migrations.Model,
  Fido.Db.ScriptRunner.Intf,
  Fido.Db.ScriptRunner.FireDac,
  Fido.Db.Migrations.Repository.Intf,
  Fido.Logging.Appenders.PermanentFile,
  Fido.Consul.DI.Registration,
  Fido.Api.Server.Consul,
  Fido.Consul.Service.Intf,
  Fido.KVStore.Intf,

  FidoApp.Constants,
  FidoApp.DI.Registration,
  FidoApp.Utils,
  FidoApp.Persistence.Repositories.DatabaseMigrations,
  FidoApp.Presentation.Controllers.ApiServers.Health,

  AuthorizationService.Constants,
  AuthorizationService.Persistence.Db.DI.Registration,
  AuthorizationService.Persistence.Gateways.DI.Registration,
  AuthorizationService.Persistence.Repositories.UserRole.DI.Registration,
  AuthorizationService.Presentation.Controllers.ApiServers.GetRoleByUserId.V1,
  AuthorizationService.Presentation.Controllers.ApiServers.SetRoleByUserId.V1,
  AuthorizationService.Domain.UseCases.SetRoleByUserId.DI.Registration,
  AuthorizationService.Domain.UseCases.GetRoleByUserId.DI.Registration,
  AuthorizationService.Domain.UseCases.ConvertToJWT.DI.Registration;

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
  PublicKeyContent: string;
  IniFile: IShared<TMemIniFile>;
  FireDacDatabaseParams: IShared<TStringList>;
  ConsulKVStore: IKVStore;
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

  PublicKeyContent := ConsulKVStore.Get('public.key', Constants.TIMEOUT);

  Container.RegisterType<TFireDacConnections>(
    function: TFireDacConnections
    begin
      Result := TFireDacPerThreadConnections.Create(FireDacDatabaseParams);
    end).AsSingleton;

  Container.RegisterType<IStatementExecutor, TFireDacStatementExecutor>.AsSingletonPerThread();

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
        IniFile.ReadString('Server', 'ServiceName', 'AuthorizationService'),
        Constants.TIMEOUT);
    end);

  Container.RegisterType<IJWTManager, TJWTManager>;

  FidoApp.DI.Registration.RegisterTokensCache(Container);

  AuthorizationService.Persistence.Db.DI.Registration.DIRegistration(Container);
  AuthorizationService.Persistence.Gateways.DI.Registration.DIRegistration(Container);
  AuthorizationService.Persistence.Repositories.UserRole.DI.Registration.DIRegistration(Container);
  AuthorizationService.Domain.UseCases.GetRoleByUserId.DI.Registration.DIRegistration(Container);
  AuthorizationService.Domain.UseCases.SetRoleByUserId.DI.Registration.DIRegistration(Container);
  AuthorizationService.Domain.UseCases.ConvertToJWT.DI.Registration.DIRegistration(Container, PublicKeyContent);

  Container.RegisterType<THealthApiServerController>;

  Container.RegisterType<TGetRoleByUserIdV1ApiServerController>;
  Container.RegisterType<TSetRoleByUserIdV1ApiServerController>;

  Container.Build;
end;

end.
