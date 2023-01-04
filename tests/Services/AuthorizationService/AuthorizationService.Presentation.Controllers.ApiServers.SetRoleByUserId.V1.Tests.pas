unit AuthorizationService.Presentation.Controllers.ApiServers.SetRoleByUserId.V1.Tests;

interface

uses
  System.SysUtils,

  DUnitX.TestFramework,

  Spring,
  Spring.Logging,
  Spring.Collections,
  Spring.Mocking,

  Fido.Exceptions,
  Fido.Types,
  Fido.Testing.Mock.Utils,
  Fido.JSON.Marshalling,
  Fido.Api.Server.Exceptions,


  AuthorizationService.Presentation.Controllers.ApiServers.SetRoleByUserId.V1,
  AuthorizationService.Persistence.Db.GetRoleByUserId.Intf,
  AuthorizationService.Persistence.Gateways.GetRoleByUserId.Intf,
  AuthorizationService.Persistence.Gateways.GetRoleByUserId,
  AuthorizationService.Persistence.Db.SetRoleByUserId.Intf,
  AuthorizationService.Persistence.Gateways.SetRoleByUserId.Intf,
  AuthorizationService.Persistence.Gateways.SetRoleByUserId,
  AuthorizationService.Persistence.Repositories.UserRole,
  AuthorizationService.Domain.Repositories.UserRole.Intf,
  AuthorizationService.Domain.UseCases.ConvertToJWT.Intf,
  AuthorizationService.Domain.UseCases.SetRoleByUserId,
  AuthorizationService.Domain.UseCases.SetRoleByUserId.Intf,
  AuthorizationService.Domain.Entities.UserRole;

type
  EAuthorizationServiceAdaptersControllersApiServersSetRoleByUserIdV1Tests = class(EFidoException);

  [TestFixture]
  TAuthorizationServiceAdaptersControllersApiServersSetRoleByUserIdV1Tests = class
  public
    [Test]
    procedure ExecuteDoesNotRaiseAnyExceptionWhenThereIsNoError;

    [Test]
    [TestCase('Zero Records', '0')]
    [TestCase('Two Records', '2')]
    procedure ExecuteRaisesESetRoleByUserIdUseCaseFailureWhenXRecordsAreUpdatedInTheDatabase(const AffectedRecords: Integer);
  end;

implementation

{ TAuthorizationServiceAdaptersControllersApiServersSetRoleByUserIdV1Tests }

procedure TAuthorizationServiceAdaptersControllersApiServersSetRoleByUserIdV1Tests.ExecuteRaisesESetRoleByUserIdUseCaseFailureWhenXRecordsAreUpdatedInTheDatabase(const AffectedRecords: Integer);
var
  Resource: Shared<TSetRoleByUserIdV1ApiServerController>;
  SetRoleByUserId: ISetRoleByUserIdUseCase;
  Repository: IUserRoleRepository;
  GetUserRoleByUserIdGateway: IGetUserRoleByUserIdGateway;
  UpsertUserRoleByUserIdGateway: IUpsertUserRoleByUserIdGateway;
  GetUserRoleByUserIdQuery: Mock<IGetUserRoleByUserIdQuery>;
  UpsertUserRoleByUserIdCommand: Mock<IUpsertUserRoleByUserIdCommand>;

  Logger: Mock<ILogger>;

  Authorization: string;
  UserId: TGuid;
  Role: string;
  UserRole: Shared<TUserRole>;
begin
  Authorization := MockUtils.SomeString;
  UserId := MockUtils.SomeGuid;
  Role := MockUtils.SomeString;
  UserRole := TUserRole.Create(UserId, Role);

  Logger := Mock<ILogger>.Create;

  GetUserRoleByUserIdQuery := Mock<IGetUserRoleByUserIdQuery>.Create;
  UpsertUserRoleByUserIdCommand := Mock<IUpsertUserRoleByUserIdCommand>.Create;
  UpsertUserRoleByUserIdCommand.Setup.Returns<Integer>(AffectedRecords).When.Exec(UserId.ToString, Role);

  GetUserRoleByUserIdGateway := TGetUserRoleByUserIdGateway.Create(GetUserRoleByUserIdQuery);
  UpsertUserRoleByUserIdGateway := TUpsertUserRoleByUserIdGateway.Create(UpsertUserRoleByUserIdCommand);

  Repository := TUserRoleRepository.Create(GetUserRoleByUserIdGateway, UpsertUserRoleByUserIdGateway);

  SetRoleByUserId := TSetRoleByUserIdUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := Repository;
    end);

  Resource := TSetRoleByUserIdV1ApiServerController.Create(

    SetRoleByUserId);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(UserId, Role);
    end,
    ESetRoleByUserIdUseCaseFailure);

  GetUserRoleByUserIdQuery.Received(Times.Never).Open(Arg.IsAny<string>);
  UpsertUserRoleByUserIdCommand.Received(Times.Once).Exec(UserId.ToString, Role);
  UpsertUserRoleByUserIdCommand.Received(Times.Never).Exec(Arg.IsNotIn<string>([UserId.ToString]), Arg.IsNotIn<string>([Role]));
end;

procedure TAuthorizationServiceAdaptersControllersApiServersSetRoleByUserIdV1Tests.ExecuteDoesNotRaiseAnyExceptionWhenThereIsNoError;
var
  Resource: Shared<TSetRoleByUserIdV1ApiServerController>;
  SetRoleByUserId: ISetRoleByUserIdUseCase;
  Repository: IUserRoleRepository;
  GetUserRoleByUserIdGateway: IGetUserRoleByUserIdGateway;
  UpsertUserRoleByUserIdGateway: IUpsertUserRoleByUserIdGateway;
  GetUserRoleByUserIdQuery: Mock<IGetUserRoleByUserIdQuery>;
  UpsertUserRoleByUserIdCommand: Mock<IUpsertUserRoleByUserIdCommand>;

  Logger: Mock<ILogger>;

  Authorization: string;
  UserId: TGuid;
  Role: string;
  UserRole: Shared<TUserRole>;
begin
  Authorization := MockUtils.SomeString;
  UserId := MockUtils.SomeGuid;
  Role := MockUtils.SomeString;
  UserRole := TUserRole.Create(UserId, Role);

  Logger := Mock<ILogger>.Create;

  GetUserRoleByUserIdQuery := Mock<IGetUserRoleByUserIdQuery>.Create;
  UpsertUserRoleByUserIdCommand := Mock<IUpsertUserRoleByUserIdCommand>.Create;
  UpsertUserRoleByUserIdCommand.Setup.Returns<Integer>(1).When.Exec(UserId.ToString, Role);

  GetUserRoleByUserIdGateway := TGetUserRoleByUserIdGateway.Create(GetUserRoleByUserIdQuery);
  UpsertUserRoleByUserIdGateway := TUpsertUserRoleByUserIdGateway.Create(UpsertUserRoleByUserIdCommand);

  Repository := TUserRoleRepository.Create(GetUserRoleByUserIdGateway, UpsertUserRoleByUserIdGateway);

  SetRoleByUserId := TSetRoleByUserIdUseCase.Create(
    function: IUserRoleRepository
    begin
      Result := Repository;
    end);

  Resource := TSetRoleByUserIdV1ApiServerController.Create(

    SetRoleByUserId);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Resource.Value.Execute(UserId, Role);
    end);

  GetUserRoleByUserIdQuery.Received(Times.Never).Open(Arg.IsAny<string>);
  UpsertUserRoleByUserIdCommand.Received(Times.Once).Exec(UserId.ToString, Role);
  UpsertUserRoleByUserIdCommand.Received(Times.Never).Exec(Arg.IsNotIn<string>([UserId.ToString]), Arg.IsNotIn<string>([Role]));
end;

initialization
  TDUnitX.RegisterTestFixture(TAuthorizationServiceAdaptersControllersApiServersSetRoleByUserIdV1Tests);

end.
