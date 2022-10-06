program Tests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  FidoApp.Utils.Tests in 'Shared\FidoApp.Utils.Tests.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.ChangeActiveStatus.V1 in '..\source\services\authentication\Presentation\Controllers\ApiServers\AuthenticationService.Presentation.Controllers.ApiServers.ChangeActiveStatus.V1.pas',
  AuthenticationService.Persistence.Db.ChangeActiveStatus.Intf in '..\source\services\authentication\Persistence\Db\AuthenticationService.Persistence.Db.ChangeActiveStatus.Intf.pas',
  AuthenticationService.Persistence.Db.Login.Intf in '..\source\services\authentication\Persistence\Db\AuthenticationService.Persistence.Db.Login.Intf.pas',
  AuthenticationService.Persistence.Db.Remove.Intf in '..\source\services\authentication\Persistence\Db\AuthenticationService.Persistence.Db.Remove.Intf.pas',
  AuthenticationService.Persistence.Db.Signup.Intf in '..\source\services\authentication\Persistence\Db\AuthenticationService.Persistence.Db.Signup.Intf.pas',
  AuthenticationService.Persistence.Repositories.User in '..\source\services\authentication\Persistence\Repositories\AuthenticationService.Persistence.Repositories.User.pas',
  AuthenticationService.Domain.Repositories.User.Intf in '..\source\services\authentication\Domain\AuthenticationService.Domain.Repositories.User.Intf.pas',
  AuthenticationService.Domain.Entities.UserStatus in '..\source\services\authentication\Domain\Entities\AuthenticationService.Domain.Entities.UserStatus.pas',
  AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf.pas',
  AuthenticationService.Domain.UseCases.ChangeActiveStatus in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.ChangeActiveStatus.pas',
  AuthenticationService.Domain.Entities.User in '..\source\services\authentication\Domain\Entities\AuthenticationService.Domain.Entities.User.pas',
  AuthenticationService.Domain.TokensCache.Abstract in '..\source\services\authentication\Domain\TokensCache\AuthenticationService.Domain.TokensCache.Abstract.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.Login.V1 in '..\source\services\authentication\Presentation\Controllers\ApiServers\AuthenticationService.Presentation.Controllers.ApiServers.Login.V1.pas',
  AuthenticationService.Domain.UseCases.Login.Intf in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.Login.Intf.pas',
  AuthenticationService.Domain.UseCases.Login in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.Login.pas',
  AuthenticationService.Domain.UseCases.Types in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.Types.pas',
  AuthenticationService.Domain.UseCases.GenerateAccessToken.Intf in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.GenerateAccessToken.Intf.pas',
  AuthenticationService.Domain.UseCases.GenerateAccessToken in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.GenerateAccessToken.pas',
  AuthenticationService.Domain.UseCases.GenerateRefreshToken.Intf in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.GenerateRefreshToken.Intf.pas',
  AuthenticationService.Domain.UseCases.GenerateRefreshToken in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.GenerateRefreshToken.pas',
  AuthenticationService.Domain.UseCases.AddRoleToToken.Intf in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.AddRoleToToken.Intf.pas',
  AuthenticationService.Domain.UseCases.AddRoleToToken in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.AddRoleToToken.pas',
  AuthenticationService.Persistence.Repositories.UserRole in '..\source\services\authentication\Persistence\Repositories\AuthenticationService.Persistence.Repositories.UserRole.pas',
  AuthenticationService.Domain.Repositories.UserRole.Intf in '..\source\services\authentication\Domain\AuthenticationService.Domain.Repositories.UserRole.Intf.pas',
  AuthenticationService.Domain.TokensCache.Intf in '..\source\services\authentication\Domain\TokensCache\AuthenticationService.Domain.TokensCache.Intf.pas',
  AuthenticationService.Domain.TokensCache.SingleInstance in '..\source\services\authentication\Domain\TokensCache\AuthenticationService.Domain.TokensCache.SingleInstance.pas',
  AuthenticationService.Domain.UseCases.RefreshToken.Intf in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.RefreshToken.Intf.pas',
  AuthenticationService.Domain.UseCases.RefreshToken in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.RefreshToken.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.RefreshToken.V1 in '..\source\services\authentication\Presentation\Controllers\ApiServers\AuthenticationService.Presentation.Controllers.ApiServers.RefreshToken.V1.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.Signup.V1 in '..\source\services\authentication\Presentation\Controllers\ApiServers\AuthenticationService.Presentation.Controllers.ApiServers.Signup.V1.pas',
  AuthenticationService.Domain.UseCases.Remove.Intf in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.Remove.Intf.pas',
  AuthenticationService.Domain.UseCases.Remove in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.Remove.pas',
  AuthenticationService.Domain.UseCases.Signup.Intf in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.Signup.Intf.pas',
  AuthenticationService.Domain.UseCases.Signup in '..\source\services\authentication\Domain\UseCases\AuthenticationService.Domain.UseCases.Signup.pas',
  AuthenticationService.Presentation.Consumers.ActivateUser in '..\source\services\authentication\Presentation\Consumers\AuthenticationService.Presentation.Consumers.ActivateUser.pas',
  AuthenticationService.Presentation.Consumers.CancelSignup in '..\source\services\authentication\Presentation\Consumers\AuthenticationService.Presentation.Consumers.CancelSignup.pas',
  AuthorizationService.Presentation.Controllers.ApiServers.GetRoleByUserId.V1 in '..\source\services\authorization\Presentation\Controllers\ApiServers\AuthorizationService.Presentation.Controllers.ApiServers.GetRoleByUserId.V1.pas',
  AuthorizationService.Domain.UseCases.GetRoleByUserId.Intf in '..\source\services\authorization\Domain\UseCases\AuthorizationService.Domain.UseCases.GetRoleByUserId.Intf.pas',
  AuthorizationService.Domain.UseCases.GetRoleByUserId in '..\source\services\authorization\Domain\UseCases\AuthorizationService.Domain.UseCases.GetRoleByUserId.pas',
  AuthorizationService.Domain.ValueObjects.RolesAndPermissions in '..\source\services\authorization\Domain\ValueObjects\AuthorizationService.Domain.ValueObjects.RolesAndPermissions.pas',
  AuthorizationService.Domain.Repositories.UserRole.Intf in '..\source\services\authorization\Domain\AuthorizationService.Domain.Repositories.UserRole.Intf.pas',
  AuthorizationService.Domain.Entities.UserRole in '..\source\services\authorization\Domain\Entities\AuthorizationService.Domain.Entities.UserRole.pas',
  AuthorizationService.Persistence.Repositories.UserRole in '..\source\services\authorization\Persistence\Repositories\AuthorizationService.Persistence.Repositories.UserRole.pas',
  AuthorizationService.Domain.UseCases.ConvertToJWT.Intf in '..\source\services\authorization\Domain\UseCases\AuthorizationService.Domain.UseCases.ConvertToJWT.Intf.pas',
  AuthorizationService.Domain.UseCases.ConvertToJWT in '..\source\services\authorization\Domain\UseCases\AuthorizationService.Domain.UseCases.ConvertToJWT.pas',
  AuthorizationService.Domain.UseCases.SetRoleByUserId.Intf in '..\source\services\authorization\Domain\UseCases\AuthorizationService.Domain.UseCases.SetRoleByUserId.Intf.pas',
  AuthorizationService.Domain.UseCases.SetRoleByUserId in '..\source\services\authorization\Domain\UseCases\AuthorizationService.Domain.UseCases.SetRoleByUserId.pas',
  AuthorizationService.Presentation.Controllers.ApiServers.SetRoleByUserId.V1 in '..\source\services\authorization\Presentation\Controllers\ApiServers\AuthorizationService.Presentation.Controllers.ApiServers.SetRoleByUserId.V1.pas',
  UsersService.Presentation.Consumers.AddUser in '..\source\services\users\Presentation\Consumers\UsersService.Presentation.Consumers.AddUser.pas',
  UsersService.Presentation.Consumers.RemoveUser in '..\source\services\users\Presentation\Consumers\UsersService.Presentation.Consumers.RemoveUser.pas',
  UsersService.Domain.Entities.User in '..\source\services\users\Domain\Entities\UsersService.Domain.Entities.User.pas',
  UsersService.Domain.UseCases.Add.Intf in '..\source\services\users\Domain\UseCases\UsersService.Domain.UseCases.Add.Intf.pas',
  UsersService.Domain.UseCases.Add in '..\source\services\users\Domain\UseCases\UsersService.Domain.UseCases.Add.pas',
  UsersService.Domain.UseCases.Remove.Intf in '..\source\services\users\Domain\UseCases\UsersService.Domain.UseCases.Remove.Intf.pas',
  UsersService.Domain.UseCases.Remove in '..\source\services\users\Domain\UseCases\UsersService.Domain.UseCases.Remove.pas',
  UsersService.Domain.Repositories.User.Intf in '..\source\services\users\Domain\UsersService.Domain.Repositories.User.Intf.pas',
  UsersService.Persistence.Repositories.User in '..\source\services\users\Persistence\Repositories\UsersService.Persistence.Repositories.User.pas',
  ClientApp.Messages in '..\source\client\ClientApp.Messages.pas',
  ClientApp.Types in '..\source\client\ClientApp.Types.pas',
  ClientApp.Models.Domain.Entities.LoginUser in '..\source\client\Models\Domain\Entities\ClientApp.Models.Domain.Entities.LoginUser.pas',
  ClientApp.Models.Domain.Entities.SignupUser in '..\source\client\Models\Domain\Entities\ClientApp.Models.Domain.Entities.SignupUser.pas',
  ClientApp.Models.Domain.Repositories.Authentication.Intf in '..\source\client\Models\Domain\ClientApp.Models.Domain.Repositories.Authentication.Intf.pas',
  ClientApp.Models.Domain.Usecases.Login.Intf in '..\source\client\Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.Login.Intf.pas',
  ClientApp.Models.Domain.Usecases.Login in '..\source\client\Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.Login.pas',
  ClientApp.Models.Domain.Usecases.ShowLoginView.Intf in '..\source\client\Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.ShowLoginView.Intf.pas',
  ClientApp.Models.Domain.Usecases.ShowLoginView in '..\source\client\Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.ShowLoginView.pas',
  ClientApp.Models.Domain.Usecases.Signup.Intf in '..\source\client\Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.Signup.Intf.pas',
  ClientApp.Models.Domain.UseCases.Signup in '..\source\client\Models\Domain\UseCases\ClientApp.Models.Domain.UseCases.Signup.pas',
  ClientApp.ViewModels.Login.Intf in '..\source\client\ViewModels\ClientApp.ViewModels.Login.Intf.pas',
  ClientApp.ViewModels.Login in '..\source\client\ViewModels\ClientApp.ViewModels.Login.pas',
  ClientApp.ViewModels.Main.Intf in '..\source\client\ViewModels\ClientApp.ViewModels.Main.Intf.pas',
  ClientApp.ViewModels.Main in '..\source\client\ViewModels\ClientApp.ViewModels.Main.pas',
  ClientApp.Models.Persistence.Repositories.Authentication in '..\source\client\Models\Persistence\Repositories\ClientApp.Models.Persistence.Repositories.Authentication.pas',
  ClientApp.Views.Login.Intf in '..\source\client\Views\ClientApp.Views.Login.Intf.pas',
  ClientApp.ViewModels.Login.Tests in 'Client\ClientApp.ViewModels.Login.Tests.pas',
  ClientApp.ViewModels.Main.Tests in 'Client\ClientApp.ViewModels.Main.Tests.pas',
  AuthenticationService.Presentation.Consumers.ActivateUser.Tests in 'Services\AuthenticationService\AuthenticationService.Presentation.Consumers.ActivateUser.Tests.pas',
  AuthenticationService.Presentation.Consumers.CancelSignup.Tests in 'Services\AuthenticationService\AuthenticationService.Presentation.Consumers.CancelSignup.Tests.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.ChangeActiveStatus.V1.Tests in 'Services\AuthenticationService\AuthenticationService.Presentation.Controllers.ApiServers.ChangeActiveStatus.V1.Tests.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.Login.V1.Tests in 'Services\AuthenticationService\AuthenticationService.Presentation.Controllers.ApiServers.Login.V1.Tests.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.RefreshToken.V1.Tests in 'Services\AuthenticationService\AuthenticationService.Presentation.Controllers.ApiServers.RefreshToken.V1.Tests.pas',
  AuthenticationService.Presentation.Controllers.ApiServers.Signup.V1.Tests in 'Services\AuthenticationService\AuthenticationService.Presentation.Controllers.ApiServers.Signup.V1.Tests.pas',
  AuthorizationService.Presentation.Controllers.ApiServers.GetRoleByUserId.V1.Tests in 'Services\AuthorizationService\AuthorizationService.Presentation.Controllers.ApiServers.GetRoleByUserId.V1.Tests.pas',
  AuthorizationService.Presentation.Controllers.ApiServers.SetRoleByUserId.V1.Tests in 'Services\AuthorizationService\AuthorizationService.Presentation.Controllers.ApiServers.SetRoleByUserId.V1.Tests.pas',
  UsersService.Presentation.Consumers.AddUser.Tests in 'Services\UsersService\UsersService.Presentation.Consumers.AddUser.Tests.pas',
  UsersService.Presentation.Consumers.RemoveUser.Tests in 'Services\UsersService\UsersService.Presentation.Consumers.RemoveUser.Tests.pas',
  FidoApp.Domain.ClientTokensCache.Tests in 'Shared\Domain\ClientTokensCache\FidoApp.Domain.ClientTokensCache.Tests.pas',
  FidoApp.Domain.UseCases.RefreshToken.Tests in 'Shared\Domain\UseCases\FidoApp.Domain.UseCases.RefreshToken.Tests.pas',
  UsersService.Domain.UseCases.GetAll.Intf in '..\source\services\users\Domain\UseCases\UsersService.Domain.UseCases.GetAll.Intf.pas',
  UsersService.Domain.UseCases.GetAll in '..\source\services\users\Domain\UseCases\UsersService.Domain.UseCases.GetAll.pas',
  UsersService.Presentation.Controllers.ApiServers.GetAll.V1 in '..\source\services\users\Presentation\Controllers\ApiServers\UsersService.Presentation.Controllers.ApiServers.GetAll.V1.pas',
  UsersService.Presentation.Controllers.ApiServers.GetAll.V1.Tests in 'Services\UsersService\UsersService.Presentation.Controllers.ApiServers.GetAll.V1.Tests.pas',
  FidoApp.Constants.Tests in 'Shared\FidoApp.Constants.Tests.pas',
  ClientApp.Models.Domain.Usecases.GetAllUsers.Intf in '..\source\client\Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.GetAllUsers.Intf.pas',
  ClientApp.Models.Domain.Usecases.GetAllUsers in '..\source\client\Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.GetAllUsers.pas',
  ClientApp.Models.Persistence.Repositories.Users in '..\source\client\Models\Persistence\Repositories\ClientApp.Models.Persistence.Repositories.Users.pas',
  ClientApp.ViewModels.Users.Intf in '..\source\client\ViewModels\ClientApp.ViewModels.Users.Intf.pas',
  ClientApp.ViewModels.Users in '..\source\client\ViewModels\ClientApp.ViewModels.Users.pas',
  ClientApp.Models.Domain.Repositories.Users.Intf in '..\source\client\Models\Domain\ClientApp.Models.Domain.Repositories.Users.Intf.pas',
  ClientApp.ViewModels.Users.Tests in 'Client\ClientApp.ViewModels.Users.Tests.pas',
  AuthenticationService.Persistence.Gateways.ChangeActiveStatus.Intf in '..\source\services\authentication\Persistence\Gateways\AuthenticationService.Persistence.Gateways.ChangeActiveStatus.Intf.pas',
  AuthenticationService.Persistence.Gateways.ChangeActiveStatus in '..\source\services\authentication\Persistence\Gateways\AuthenticationService.Persistence.Gateways.ChangeActiveStatus.pas',
  AuthenticationService.Persistence.Gateways.Login.Intf in '..\source\services\authentication\Persistence\Gateways\AuthenticationService.Persistence.Gateways.Login.Intf.pas',
  AuthenticationService.Persistence.Gateways.Login in '..\source\services\authentication\Persistence\Gateways\AuthenticationService.Persistence.Gateways.Login.pas',
  AuthenticationService.Persistence.Gateways.Remove.Intf in '..\source\services\authentication\Persistence\Gateways\AuthenticationService.Persistence.Gateways.Remove.Intf.pas',
  AuthenticationService.Persistence.Gateways.Remove in '..\source\services\authentication\Persistence\Gateways\AuthenticationService.Persistence.Gateways.Remove.pas',
  AuthenticationService.Persistence.Gateways.Signup.Intf in '..\source\services\authentication\Persistence\Gateways\AuthenticationService.Persistence.Gateways.Signup.Intf.pas',
  AuthenticationService.Persistence.Gateways.Signup in '..\source\services\authentication\Persistence\Gateways\AuthenticationService.Persistence.Gateways.Signup.pas',
  AuthorizationService.Persistence.Gateways.GetRoleByUserId.Intf in '..\source\services\authorization\Persistence\Gateways\AuthorizationService.Persistence.Gateways.GetRoleByUserId.Intf.pas',
  AuthorizationService.Persistence.Gateways.GetRoleByUserId in '..\source\services\authorization\Persistence\Gateways\AuthorizationService.Persistence.Gateways.GetRoleByUserId.pas',
  AuthorizationService.Persistence.Gateways.SetRoleByUserId.Intf in '..\source\services\authorization\Persistence\Gateways\AuthorizationService.Persistence.Gateways.SetRoleByUserId.Intf.pas',
  AuthorizationService.Persistence.Gateways.SetRoleByUserId in '..\source\services\authorization\Persistence\Gateways\AuthorizationService.Persistence.Gateways.SetRoleByUserId.pas',
  AuthorizationService.Persistence.Db.GetRoleByUserId.Intf in '..\source\services\authorization\Persistence\Db\AuthorizationService.Persistence.Db.GetRoleByUserId.Intf.pas',
  AuthorizationService.Persistence.Db.SetRoleByUserId.Intf in '..\source\services\authorization\Persistence\Db\AuthorizationService.Persistence.Db.SetRoleByUserId.Intf.pas',
  UsersService.Persistence.Db.Add.Intf in '..\source\services\users\Persistence\Db\UsersService.Persistence.Db.Add.Intf.pas',
  UsersService.Persistence.Db.GetAll.Intf in '..\source\services\users\Persistence\Db\UsersService.Persistence.Db.GetAll.Intf.pas',
  UsersService.Persistence.Db.GetCount.Intf in '..\source\services\users\Persistence\Db\UsersService.Persistence.Db.GetCount.Intf.pas',
  UsersService.Persistence.Db.Remove.Intf in '..\source\services\users\Persistence\Db\UsersService.Persistence.Db.Remove.Intf.pas',
  UsersService.Persistence.Db.Types in '..\source\services\users\Persistence\Db\UsersService.Persistence.Db.Types.pas',
  UsersService.Persistence.Gateways.Add.Intf in '..\source\services\users\Persistence\Gateways\UsersService.Persistence.Gateways.Add.Intf.pas',
  UsersService.Persistence.Gateways.Add in '..\source\services\users\Persistence\Gateways\UsersService.Persistence.Gateways.Add.pas',
  UsersService.Persistence.Gateways.GetAll.Intf in '..\source\services\users\Persistence\Gateways\UsersService.Persistence.Gateways.GetAll.Intf.pas',
  UsersService.Persistence.Gateways.GetAll in '..\source\services\users\Persistence\Gateways\UsersService.Persistence.Gateways.GetAll.pas',
  UsersService.Persistence.Gateways.GetCount.Intf in '..\source\services\users\Persistence\Gateways\UsersService.Persistence.Gateways.GetCount.Intf.pas',
  UsersService.Persistence.Gateways.GetCount in '..\source\services\users\Persistence\Gateways\UsersService.Persistence.Gateways.GetCount.pas',
  UsersService.Persistence.Gateways.Remove.Intf in '..\source\services\users\Persistence\Gateways\UsersService.Persistence.Gateways.Remove.Intf.pas',
  UsersService.Persistence.Gateways.Remove in '..\source\services\users\Persistence\Gateways\UsersService.Persistence.Gateways.Remove.pas',
  FidoApp.Persistence.ApiClients.Authentication.V1.Intf.Tests in 'Shared\Persistence\ApiClients\FidoApp.Persistence.ApiClients.Authentication.V1.Intf.Tests.pas',
  FidoApp.Persistence.ApiClients.Configuration.Tokens.Tests in 'Shared\Persistence\ApiClients\FidoApp.Persistence.ApiClients.Configuration.Tokens.Tests.pas';

{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger : ITestLogger;
{$ENDIF}
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      {$IFNDEF CI}
      System.Readln;
      {$ENDIF}
    end;
  end;
{$ENDIF}
end.
