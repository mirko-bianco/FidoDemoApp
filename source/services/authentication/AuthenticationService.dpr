program AuthenticationService;

{$APPTYPE CONSOLE}

{$R *.res}


{$R 'AuthenticationService.Queries.res' 'AuthenticationService.Queries.rc'}

uses
  System.Classes,
  System.SysUtils,
  Generics.Collections,
  FireDAC.Comp.UI,
  Spring,
  Spring.Container,
  Spring.Logging,
  Fido.Types,
  Fido.Functional,
  Fido.Db.Connections.FireDac,
  Fido.Api.Server.Intf,
  Fido.JWT.Manager.Intf,
  Fido.Db.Migrations.Model.Intf,
  Fido.KVStore.Intf,
  Fido.JSON.Marshalling,
  Fido.EventsDriven.Subscriber.Intf,
  FidoApp.Constants,
  FidoApp.Utils,
  FidoApp.Types,
  FidoApp.Persistence.Gateways.Authorization.Intf,
  FidoApp.Presentation.Controllers.ApiServers.Health,
  FidoApp.Domain.Usecases.RefreshToken.Intf,
  AuthenticationService.DI.Registration in 'AuthenticationService.DI.Registration.pas',
  AuthenticationService.Constants in 'AuthenticationService.Constants.pas',
  AuthenticationService.Domain.Entities.User in 'Domain\Entities\AuthenticationService.Domain.Entities.User.pas',
  AuthenticationService.Domain.Entities.UserStatus in 'Domain\Entities\AuthenticationService.Domain.Entities.UserStatus.pas',
  AuthenticationService.Domain.TokensCache.Abstract in 'Domain\TokensCache\AuthenticationService.Domain.TokensCache.Abstract.pas',
  AuthenticationService.Domain.TokensCache.Intf in 'Domain\TokensCache\AuthenticationService.Domain.TokensCache.Intf.pas',
  AuthenticationService.Domain.TokensCache.KVStore in 'Domain\TokensCache\AuthenticationService.Domain.TokensCache.KVStore.pas',
  AuthenticationService.Domain.TokensCache.SingleInstance in 'Domain\TokensCache\AuthenticationService.Domain.TokensCache.SingleInstance.pas',
  AuthenticationService.Domain.Repositories.User.Intf in 'Domain\AuthenticationService.Domain.Repositories.User.Intf.pas',
  AuthenticationService.Domain.Repositories.UserRole.Intf in 'Domain\AuthenticationService.Domain.Repositories.UserRole.Intf.pas',
  AuthenticationService.Domain.UseCases.AddRoleToToken.DI.Registration in 'Domain\UseCases\AuthenticationService.Domain.UseCases.AddRoleToToken.DI.Registration.pas',
  AuthenticationService.Domain.UseCases.AddRoleToToken.Intf in 'Domain\UseCases\AuthenticationService.Domain.UseCases.AddRoleToToken.Intf.pas',
  AuthenticationService.Domain.UseCases.AddRoleToToken in 'Domain\UseCases\AuthenticationService.Domain.UseCases.AddRoleToToken.pas',
  AuthenticationService.Domain.UseCases.ChangeActiveStatus.DI.Registration in 'Domain\UseCases\AuthenticationService.Domain.UseCases.ChangeActiveStatus.DI.Registration.pas',
  AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf in 'Domain\UseCases\AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf.pas',
  AuthenticationService.Domain.UseCases.ChangeActiveStatus in 'Domain\UseCases\AuthenticationService.Domain.UseCases.ChangeActiveStatus.pas',
  AuthenticationService.Domain.UseCases.GenerateAccessToken.DI.Registration in 'Domain\UseCases\AuthenticationService.Domain.UseCases.GenerateAccessToken.DI.Registration.pas',
  AuthenticationService.Domain.UseCases.GenerateAccessToken.Intf in 'Domain\UseCases\AuthenticationService.Domain.UseCases.GenerateAccessToken.Intf.pas',
  AuthenticationService.Domain.UseCases.GenerateAccessToken in 'Domain\UseCases\AuthenticationService.Domain.UseCases.GenerateAccessToken.pas',
  AuthenticationService.Domain.UseCases.GenerateRefreshToken.DI.Registration in 'Domain\UseCases\AuthenticationService.Domain.UseCases.GenerateRefreshToken.DI.Registration.pas',
  AuthenticationService.Domain.UseCases.GenerateRefreshToken.Intf in 'Domain\UseCases\AuthenticationService.Domain.UseCases.GenerateRefreshToken.Intf.pas',
  AuthenticationService.Domain.UseCases.GenerateRefreshToken in 'Domain\UseCases\AuthenticationService.Domain.UseCases.GenerateRefreshToken.pas',
  AuthenticationService.Domain.UseCases.Login.DI.Registration in 'Domain\UseCases\AuthenticationService.Domain.UseCases.Login.DI.Registration.pas',
  AuthenticationService.Domain.UseCases.Login.Intf in 'Domain\UseCases\AuthenticationService.Domain.UseCases.Login.Intf.pas',
  AuthenticationService.Domain.UseCases.Login in 'Domain\UseCases\AuthenticationService.Domain.UseCases.Login.pas',
  AuthenticationService.Domain.UseCases.RefreshToken.DI.Registration in 'Domain\UseCases\AuthenticationService.Domain.UseCases.RefreshToken.DI.Registration.pas',
  AuthenticationService.Domain.UseCases.RefreshToken.Intf in 'Domain\UseCases\AuthenticationService.Domain.UseCases.RefreshToken.Intf.pas',
  AuthenticationService.Domain.UseCases.RefreshToken in 'Domain\UseCases\AuthenticationService.Domain.UseCases.RefreshToken.pas',
  AuthenticationService.Domain.UseCases.Remove.DI.Registration in 'Domain\UseCases\AuthenticationService.Domain.UseCases.Remove.DI.Registration.pas',
  AuthenticationService.Domain.UseCases.Remove.Intf in 'Domain\UseCases\AuthenticationService.Domain.UseCases.Remove.Intf.pas',
  AuthenticationService.Domain.UseCases.Remove in 'Domain\UseCases\AuthenticationService.Domain.UseCases.Remove.pas',
  AuthenticationService.Domain.UseCases.Signup.DI.Registration in 'Domain\UseCases\AuthenticationService.Domain.UseCases.Signup.DI.Registration.pas',
  AuthenticationService.Domain.UseCases.Signup.Intf in 'Domain\UseCases\AuthenticationService.Domain.UseCases.Signup.Intf.pas',
  AuthenticationService.Domain.UseCases.Signup in 'Domain\UseCases\AuthenticationService.Domain.UseCases.Signup.pas',
  AuthenticationService.Domain.UseCases.Types in 'Domain\UseCases\AuthenticationService.Domain.UseCases.Types.pas',
  AuthenticationService.Persistence.Repositories.DI.Registration in 'Persistence\Repositories\AuthenticationService.Persistence.Repositories.DI.Registration.pas',
  AuthenticationService.Persistence.Repositories.User in 'Persistence\Repositories\AuthenticationService.Persistence.Repositories.User.pas',
  AuthenticationService.Persistence.Repositories.UserRole in 'Persistence\Repositories\AuthenticationService.Persistence.Repositories.UserRole.pas',
  AuthenticationService.Presentation.Consumers.ActivateUser in 'Presentation\Consumers\AuthenticationService.Presentation.Consumers.ActivateUser.pas',
  AuthenticationService.Presentation.Consumers.CancelSignup in 'Presentation\Consumers\AuthenticationService.Presentation.Consumers.CancelSignup.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.ChangeActiveStatus.V1 in 'Presentation\Controllers\ApiServers\AuthenticationService.Presentation.Controllers.ApiServers.ChangeActiveStatus.V1.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.Login.V1 in 'Presentation\Controllers\ApiServers\AuthenticationService.Presentation.Controllers.ApiServers.Login.V1.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.RefreshToken.V1 in 'Presentation\Controllers\ApiServers\AuthenticationService.Presentation.Controllers.ApiServers.RefreshToken.V1.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.Signup.V1 in 'Presentation\Controllers\ApiServers\AuthenticationService.Presentation.Controllers.ApiServers.Signup.V1.pas',
  AuthenticationService.Persistence.Gateways.DI.Registration in 'Persistence\Gateways\AuthenticationService.Persistence.Gateways.DI.Registration.pas',
  AuthenticationService.Persistence.Db.ChangeActiveStatus.Intf in 'Persistence\Db\AuthenticationService.Persistence.Db.ChangeActiveStatus.Intf.pas',
  AuthenticationService.Persistence.Db.Login.Intf in 'Persistence\Db\AuthenticationService.Persistence.Db.Login.Intf.pas',
  AuthenticationService.Persistence.Db.Remove.Intf in 'Persistence\Db\AuthenticationService.Persistence.Db.Remove.Intf.pas',
  AuthenticationService.Persistence.Db.Signup.Intf in 'Persistence\Db\AuthenticationService.Persistence.Db.Signup.Intf.pas',
  AuthenticationService.Persistence.Db.DI.Registration in 'Persistence\Db\AuthenticationService.Persistence.Db.DI.Registration.pas',
  AuthenticationService.Persistence.Gateways.ChangeActiveStatus.Intf in 'Persistence\Gateways\AuthenticationService.Persistence.Gateways.ChangeActiveStatus.Intf.pas',
  AuthenticationService.Persistence.Gateways.ChangeActiveStatus in 'Persistence\Gateways\AuthenticationService.Persistence.Gateways.ChangeActiveStatus.pas',
  AuthenticationService.Persistence.Gateways.Login.Intf in 'Persistence\Gateways\AuthenticationService.Persistence.Gateways.Login.Intf.pas',
  AuthenticationService.Persistence.Gateways.Login in 'Persistence\Gateways\AuthenticationService.Persistence.Gateways.Login.pas',
  AuthenticationService.Persistence.Gateways.Remove.Intf in 'Persistence\Gateways\AuthenticationService.Persistence.Gateways.Remove.Intf.pas',
  AuthenticationService.Persistence.Gateways.Remove in 'Persistence\Gateways\AuthenticationService.Persistence.Gateways.Remove.pas',
  AuthenticationService.Persistence.Gateways.Signup.Intf in 'Persistence\Gateways\AuthenticationService.Persistence.Gateways.Signup.Intf.pas',
  AuthenticationService.Persistence.Gateways.Signup in 'Persistence\Gateways\AuthenticationService.Persistence.Gateways.Signup.pas';

type
  TRefreshTokensData = record
  private
    FUseCase: IRefreshTokenUseCase;
    FCurrentToken: string;
  public
    constructor Create(const UseCase: IRefreshTokenUseCase; const CurrentToken: string);

    property UseCase: IRefreshTokenUseCase read FUseCase;
    property CurrentToken: string read FCurrentToken;
  end;

{ TRefreshTokensData }

constructor TRefreshTokensData.Create(const UseCase: IRefreshTokenUseCase; const CurrentToken: string);
begin
  FUseCase := UseCase;
  FCurrentToken := CurrentToken;
end;


function RefreshTokens(const Params: TRefreshTokensData): Context<TTokens>;
begin
  Result := Params.UseCase.Run(Params.CurrentToken);
end;

var
  Cursor: Shared<TFDGUIxWaitCursor>;
  Server: IApiServer;
  Container: Shared<TContainer>;
  EventsDrivenSubscriber: IEventsDrivenSubscriber;
begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  Container := TContainer.Create;
  AuthenticationService.DI.Registration.DIRegistration(Container);

  Cursor := InitializeFireDacCursor;

  Utils.DbMigrations.Run(
    Container.Value.Resolve<IDatabaseMigrationsModel>,
    DATABASENAME);

  EventsDrivenSubscriber := Container.Value.Resolve<IEventsDrivenSubscriber>;

  Server := Container.Value.Resolve<IApiServer>;
  try
    try
      Utils.Apis.Server.Middlewares.Register(
        Server,
        Container.Value.Resolve<IJWTManager>,
        Container.Value.Resolve<IKVStore>.Get('public.key', Constants.TIMEOUT),
        function(const CurrentRefreshToken: string; out AccessToken: string; out RefreshToken: string): Boolean
        var
          RefreshTokenUseCase: IRefreshTokenUseCase;
          Tokens: TTokens;
        begin
          Result := False;
          RefreshTokenUseCase := Container.Value.Resolve<IRefreshTokenUseCase>;
          try
            Tokens := Context<TRefreshTokensData>.
              New(TRefreshTokensData.Create(RefreshTokenUseCase, CurrentRefreshToken)).
              Map<TTokens>(RefreshTokens);
            AccessToken := Tokens.AccessToken;
            RefreshToken := Tokens.RefreshToken;
            Result := True;
          except
            on E: Exception do
              Container.Value.Resolve<ILogger>.Error(E.Message, E);
          end;
        end,
        function(const Authorization: string; const RefreshToken: string): IUserRoleAndPermissions
        begin
          Result := Utils.Apis.Server.Jwt.ExtractUserRoleAndPermissions(Authorization);
        end);

      Server.RegisterResource(Container.Value.Resolve<THealthApiServerController>);
      Server.RegisterResource(Container.Value.Resolve<TLoginV1ApiServerController>);
      Server.RegisterResource(Container.Value.Resolve<TReFreshTokenV1ApiServerController>);
      Server.RegisterResource(Container.Value.Resolve<TSignupV1ApiServerController>);
      Server.RegisterResource(Container.Value.Resolve<TChangeActiveStatusV1ApiServerController>);
      Server.SetActive(True);

      EventsDrivenSubscriber.RegisterConsumer(Container.Value.Resolve<TCancelSignupConsumerController>);
      EventsDrivenSubscriber.RegisterConsumer(Container.Value.Resolve<TActivateUserConsumerController>);

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
