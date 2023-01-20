program AuthorizationService;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

{$R *.res}
{$R 'AuthorizationService.Queries.res' 'AuthorizationService.Queries.rc'}

uses
  System.Classes,
  System.SysUtils,
  FireDAC.Comp.UI,
  Spring,
  Spring.Logging,
  Spring.Container,
  Spring.Collections,
  Fido.Types,
  Fido.Functional,
  Fido.Db.Connections.FireDac,
  Fido.Api.Server.Intf,
  Fido.JWT.Manager.Intf,
  Fido.Db.Migrations.Model.Intf,
  Fido.JSON.Marshalling,
  Fido.KVStore.Intf,
  FidoApp.Constants,
  FidoApp.Types,
  FidoApp.Utils,
  FidoApp.Persistence.ApiClients.Authorization.V1.Intf,
  FidoApp.Presentation.Controllers.ApiServers.Health,
  FidoApp.Domain.Usecases.RefreshToken.Intf,
  AuthorizationService.DI.Registration in 'AuthorizationService.DI.Registration.pas',
  AuthorizationService.Constants in 'AuthorizationService.Constants.pas',
  AuthorizationService.Domain.Entities.UserRole in 'Domain\Entities\AuthorizationService.Domain.Entities.UserRole.pas',
  AuthorizationService.Domain.ValueObjects.RolesAndPermissions in 'Domain\ValueObjects\AuthorizationService.Domain.ValueObjects.RolesAndPermissions.pas',
  AuthorizationService.Domain.Repositories.UserRole.Intf in 'Domain\AuthorizationService.Domain.Repositories.UserRole.Intf.pas',
  AuthorizationService.Domain.UseCases.ConvertToJWT.DI.Registration in 'Domain\UseCases\AuthorizationService.Domain.UseCases.ConvertToJWT.DI.Registration.pas',
  AuthorizationService.Domain.UseCases.ConvertToJWT.Intf in 'Domain\UseCases\AuthorizationService.Domain.UseCases.ConvertToJWT.Intf.pas',
  AuthorizationService.Domain.UseCases.ConvertToJWT in 'Domain\UseCases\AuthorizationService.Domain.UseCases.ConvertToJWT.pas',
  AuthorizationService.Domain.UseCases.GetRoleByUserId.DI.Registration in 'Domain\UseCases\AuthorizationService.Domain.UseCases.GetRoleByUserId.DI.Registration.pas',
  AuthorizationService.Domain.UseCases.GetRoleByUserId.Intf in 'Domain\UseCases\AuthorizationService.Domain.UseCases.GetRoleByUserId.Intf.pas',
  AuthorizationService.Domain.UseCases.GetRoleByUserId in 'Domain\UseCases\AuthorizationService.Domain.UseCases.GetRoleByUserId.pas',
  AuthorizationService.Domain.UseCases.SetRoleByUserId.DI.Registration in 'Domain\UseCases\AuthorizationService.Domain.UseCases.SetRoleByUserId.DI.Registration.pas',
  AuthorizationService.Domain.UseCases.SetRoleByUserId.Intf in 'Domain\UseCases\AuthorizationService.Domain.UseCases.SetRoleByUserId.Intf.pas',
  AuthorizationService.Domain.UseCases.SetRoleByUserId in 'Domain\UseCases\AuthorizationService.Domain.UseCases.SetRoleByUserId.pas',
  AuthorizationService.Persistence.Repositories.UserRole.DI.Registration in 'Persistence\Repositories\AuthorizationService.Persistence.Repositories.UserRole.DI.Registration.pas',
  AuthorizationService.Persistence.Repositories.UserRole in 'Persistence\Repositories\AuthorizationService.Persistence.Repositories.UserRole.pas',
  AuthorizationService.Presentation.Controllers.ApiServers.GetRoleByUserId.V1 in 'Presentation\Controllers\ApiServers\AuthorizationService.Presentation.Controllers.ApiServers.GetRoleByUserId.V1.pas',
  AuthorizationService.Presentation.Controllers.ApiServers.SetRoleByUserId.V1 in 'Presentation\Controllers\ApiServers\AuthorizationService.Presentation.Controllers.ApiServers.SetRoleByUserId.V1.pas',
  AuthorizationService.Persistence.Db.DI.Registration in 'Persistence\Db\AuthorizationService.Persistence.Db.DI.Registration.pas',
  AuthorizationService.Persistence.Db.GetRoleByUserId.Intf in 'Persistence\Db\AuthorizationService.Persistence.Db.GetRoleByUserId.Intf.pas',
  AuthorizationService.Persistence.Db.SetRoleByUserId.Intf in 'Persistence\Db\AuthorizationService.Persistence.Db.SetRoleByUserId.Intf.pas',
  AuthorizationService.Persistence.Gateways.GetRoleByUserId.Intf in 'Persistence\Gateways\AuthorizationService.Persistence.Gateways.GetRoleByUserId.Intf.pas',
  AuthorizationService.Persistence.Gateways.GetRoleByUserId in 'Persistence\Gateways\AuthorizationService.Persistence.Gateways.GetRoleByUserId.pas',
  AuthorizationService.Persistence.Gateways.DI.Registration in 'Persistence\Gateways\AuthorizationService.Persistence.Gateways.DI.Registration.pas',
  AuthorizationService.Persistence.Gateways.SetRoleByUserId.Intf in 'Persistence\Gateways\AuthorizationService.Persistence.Gateways.SetRoleByUserId.Intf.pas',
  AuthorizationService.Persistence.Gateways.SetRoleByUserId in 'Persistence\Gateways\AuthorizationService.Persistence.Gateways.SetRoleByUserId.pas';

var
  Cursor: IShared<TFDGUIxWaitCursor>;
  Server: IApiServer;
  Container: IShared<TContainer>;
  ConsulKVStore: IKVStore;
begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  Container := Shared.Make(TContainer.Create);
  AuthorizationService.DI.Registration.DIRegistration(Container);

  Cursor := Shared.Make(InitializeFireDacCursor);

  Utils.DbMigrations.Run(
    Container.Resolve<IDatabaseMigrationsModel>,
    DATABASENAME);

  Server := Container.Resolve<IApiServer>;
  try
    try
      ConsulKVStore := Container.Resolve<IKVStore>;

      Utils.Apis.Server.Middlewares.Register(
        Server,
        Container.Resolve<ILogger>,
        Container.Resolve<IJWTManager>,
        ConsulKVStore.Get('public.key', Constants.TIMEOUT),
        function(const CurrentRefreshToken: string; out AccessToken: string; out RefreshToken: string): Boolean
        var
          RefreshTokenUseCase: IRefreshTokenUseCase;
          Api: IAuthorizationV1ApiClient;
          Configuration: IAuthorizationV1ApiClientConfiguration;
        begin
          Result := True;
          try
            RefreshTokenUseCase := Container.Resolve<IRefreshTokenUseCase>;
            RefreshTokenUseCase.Run.Value;
            Api := Container.Resolve<IAuthorizationV1ApiClient>;
            Configuration := Api.GetConfiguration as IAuthorizationV1ApiClientConfiguration;
            AccessToken := Configuration.GetAuthorization;
            RefreshToken := Configuration.GetRefreshToken;
          except
            on E: Exception do
            begin
              Container.Resolve<ILogger>.Error(E.Message, E);
              Result := False;
            end;
          end;
        end,
        function(const Authorization: string; const RefreshToken: string): IUserRoleAndPermissions
        begin
          Result := Utils.Apis.Server.Jwt.ExtractUserRoleAndPermissions(Authorization);
        end);

      Server.RegisterResource(Container.Resolve<THealthApiServerController>);
      Server.RegisterResource(Container.Resolve<TGetRoleByUserIdV1ApiServerController>);
      Server.RegisterResource(Container.Resolve<TSetRoleByUserIdV1ApiServerController>);
      Server.SetActive(True);

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
