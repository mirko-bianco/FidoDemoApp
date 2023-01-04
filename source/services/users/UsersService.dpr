program UsersService;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

{$R *.res}
{$R 'UsersService.Queries.res' 'UsersService.Queries.rc'}

uses
  System.Classes,
  System.SysUtils,
  FireDAC.Comp.UI,
  Spring,
  Spring.Logging,
  Spring.Container,
  Fido.Types,
  Fido.Functional,
  Fido.Db.Connections.FireDac,
  Fido.Api.Server.Intf,
  Fido.Db.Migrations.Model.Intf,
  Fido.EventsDriven.Subscriber.Intf,
  Fido.JWT.Manager.Intf,
  Fido.KVStore.Intf,
  Fido.JSON.Marshalling,
  FidoApp.Constants,
  FidoApp.Utils,
  FidoApp.Types,
  FidoApp.Persistence.ApiClients.Authorization.V1.Intf,
  FidoApp.Presentation.Controllers.ApiServers.Health,
  FidoApp.Domain.Usecases.RefreshToken.Intf,
  UsersService.DI.Registration in 'UsersService.DI.Registration.pas',
  UsersService.Constants in 'UsersService.Constants.pas',
  UsersService.Domain.Entities.User in 'Domain\Entities\UsersService.Domain.Entities.User.pas',
  UsersService.Domain.Repositories.User.Intf in 'Domain\UsersService.Domain.Repositories.User.Intf.pas',
  UsersService.Domain.UseCases.Add.DI.Registration in 'Domain\UseCases\UsersService.Domain.UseCases.Add.DI.Registration.pas',
  UsersService.Domain.UseCases.Add.Intf in 'Domain\UseCases\UsersService.Domain.UseCases.Add.Intf.pas',
  UsersService.Domain.UseCases.Add in 'Domain\UseCases\UsersService.Domain.UseCases.Add.pas',
  UsersService.Domain.UseCases.Remove.DI.Registration in 'Domain\UseCases\UsersService.Domain.UseCases.Remove.DI.Registration.pas',
  UsersService.Domain.UseCases.Remove.Intf in 'Domain\UseCases\UsersService.Domain.UseCases.Remove.Intf.pas',
  UsersService.Domain.UseCases.Remove in 'Domain\UseCases\UsersService.Domain.UseCases.Remove.pas',
  UsersService.Persistence.Repositories.DI.Registration in 'Persistence\Repositories\UsersService.Persistence.Repositories.DI.Registration.pas',
  UsersService.Persistence.Repositories.User in 'Persistence\Repositories\UsersService.Persistence.Repositories.User.pas',
  UsersService.Presentation.Consumers.AddUser in 'Presentation\Consumers\UsersService.Presentation.Consumers.AddUser.pas',
  UsersService.Presentation.Consumers.RemoveUser in 'Presentation\Consumers\UsersService.Presentation.Consumers.RemoveUser.pas',
  UsersService.Presentation.Controllers.ApiServers.GetAll.V1 in 'Presentation\Controllers\ApiServers\UsersService.Presentation.Controllers.ApiServers.GetAll.V1.pas',
  UsersService.Domain.UseCases.GetAll.Intf in 'Domain\UseCases\UsersService.Domain.UseCases.GetAll.Intf.pas',
  UsersService.Domain.UseCases.GetAll in 'Domain\UseCases\UsersService.Domain.UseCases.GetAll.pas',
  UsersService.Domain.UseCases.GetAll.DI.Registration in 'Domain\UseCases\UsersService.Domain.UseCases.GetAll.DI.Registration.pas',
  UsersService.Persistence.Db.Add.Intf in 'Persistence\Db\UsersService.Persistence.Db.Add.Intf.pas',
  UsersService.Persistence.Db.GetAll.Intf in 'Persistence\Db\UsersService.Persistence.Db.GetAll.Intf.pas',
  UsersService.Persistence.Db.GetCount.Intf in 'Persistence\Db\UsersService.Persistence.Db.GetCount.Intf.pas',
  UsersService.Persistence.Db.Remove.Intf in 'Persistence\Db\UsersService.Persistence.Db.Remove.Intf.pas',
  UsersService.Persistence.Db.Types in 'Persistence\Db\UsersService.Persistence.Db.Types.pas',
  UsersService.Persistence.Gateways.Add.Intf in 'Persistence\Gateways\UsersService.Persistence.Gateways.Add.Intf.pas',
  UsersService.Persistence.Db.DI.Registration in 'Persistence\Db\UsersService.Persistence.Db.DI.Registration.pas',
  UsersService.Persistence.Gateways.Add in 'Persistence\Gateways\UsersService.Persistence.Gateways.Add.pas',
  UsersService.Persistence.Gateways.DI.Registration in 'Persistence\Gateways\UsersService.Persistence.Gateways.DI.Registration.pas',
  UsersService.Persistence.Gateways.GetAll.Intf in 'Persistence\Gateways\UsersService.Persistence.Gateways.GetAll.Intf.pas',
  UsersService.Persistence.Gateways.GetAll in 'Persistence\Gateways\UsersService.Persistence.Gateways.GetAll.pas',
  UsersService.Persistence.Gateways.GetCount.Intf in 'Persistence\Gateways\UsersService.Persistence.Gateways.GetCount.Intf.pas',
  UsersService.Persistence.Gateways.GetCount in 'Persistence\Gateways\UsersService.Persistence.Gateways.GetCount.pas',
  UsersService.Persistence.Gateways.Remove.Intf in 'Persistence\Gateways\UsersService.Persistence.Gateways.Remove.Intf.pas',
  UsersService.Persistence.Gateways.Remove in 'Persistence\Gateways\UsersService.Persistence.Gateways.Remove.pas';

var
  Cursor: Shared<TFDGUIxWaitCursor>;
  Server: IApiServer;
  Container: Shared<TContainer>;
  EventsDrivenSubscriber: IEventsDrivenSubscriber;
  ConsulKVStore: IKVStore;
begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  Container := TContainer.Create;
  UsersService.DI.Registration.DIRegistration(Container);

  Cursor := InitializeFireDacCursor;

  Utils.DbMigrations.Run(
    Container.Value.Resolve<IDatabaseMigrationsModel>,
    DATABASENAME);

  ConsulKVStore := Container.Value.Resolve<IKVStore>;

  EventsDrivenSubscriber := Container.Value.Resolve<IEventsDrivenSubscriber>;
  Server := Container.Value.Resolve<IApiServer>;
  try
    try
      Utils.Apis.Server.Middlewares.Register(
        Server,
        Container.Value.Resolve<ILogger>,
        Container.Value.Resolve<IJWTManager>,
        ConsulKVStore.Get('public.key', Constants.TIMEOUT),
        function(const CurrentRefreshToken: string; out AccessToken: string; out RefreshToken: string): Boolean
        var
          RefreshTokenUseCase: IRefreshTokenUseCase;
          Api: IAuthorizationV1ApiClient;
          Configuration: IAuthorizationV1ApiClientConfiguration;
        begin
          Result := True;
          try
            RefreshTokenUseCase := Container.Value.Resolve<IRefreshTokenUseCase>;
            RefreshTokenUseCase.Run.Value;
            Api := Container.Value.Resolve<IAuthorizationV1ApiClient>;
            Configuration := Api.GetConfiguration as IAuthorizationV1ApiClientConfiguration;
            AccessToken := Configuration.GetAuthorization;
            RefreshToken := Configuration.GetRefreshToken;
          except
            on E: Exception do
            begin
              Container.Value.Resolve<ILogger>.Error(E.Message, E);
              Result := False;
            end;
          end;
        end,
        function(const Authorization: string; const RefreshToken: string): IUserRoleAndPermissions
        begin
          Result := Utils.Apis.Server.Jwt.ExtractUserRoleAndPermissions(Authorization);
        end);

      Server.RegisterResource(Container.Value.Resolve<THealthApiServerController>);
      Server.RegisterResource(Container.Value.Resolve<TGetAllV1ApiServerController>);

      Server.SetActive(True);

      EventsDrivenSubscriber.RegisterGlobalMiddleware(Utils.Consumers.Middlewares.GetLogged(Container.Value.Resolve<ILogger>));
      EventsDrivenSubscriber.RegisterConsumer(Container.Value.Resolve<TAddUserConsumerController>);
      EventsDrivenSubscriber.RegisterConsumer(Container.Value.Resolve<TRemoveUserConsumerController>);

      {$IFDEF LINUX}
      while true do Sleep(1000);
      {$ELSE}
      ReadLn;
      {$ENDIF}
    except
      on E: Exception do
      begin
        Writeln(E.ClassName, ': ', E.Message);
        Readln;
      end;
    end;
  finally
    Server.SetActive(False);
  end;
end.
