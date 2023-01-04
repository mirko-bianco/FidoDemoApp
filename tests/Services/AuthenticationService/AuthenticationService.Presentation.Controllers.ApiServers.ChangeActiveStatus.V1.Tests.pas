unit AuthenticationService.Presentation.Controllers.ApiServers.ChangeActiveStatus.V1.Tests;

interface

uses
  System.SysUtils,

  DUnitX.TestFramework,

  Spring,
  Spring.Logging,
  Spring.Mocking,

  Fido.Utilities,
  Fido.Exceptions,
  Fido.Types,
  Fido.Testing.Mock.Utils,
  Fido.JSON.Marshalling,
  Fido.Api.Server.Exceptions,

  AuthenticationService.Presentation.Controllers.ApiServers.ChangeActiveStatus.V1,
  AuthenticationService.Persistence.Db.ChangeActiveStatus.Intf,
  AuthenticationService.Persistence.Db.Login.Intf,
  AuthenticationService.Persistence.Db.Remove.Intf,
  AuthenticationService.Persistence.Db.Signup.Intf,
  AuthenticationService.Persistence.Gateways.ChangeActiveStatus.Intf,
  AuthenticationService.Persistence.Gateways.ChangeActiveStatus,
  AuthenticationService.Persistence.Gateways.Login.Intf,
  AuthenticationService.Persistence.Gateways.Login,
  AuthenticationService.Persistence.Gateways.Remove.Intf,
  AuthenticationService.Persistence.Gateways.Remove,
  AuthenticationService.Persistence.Gateways.Signup.Intf,
  AuthenticationService.Persistence.Gateways.Signup,
  AuthenticationService.Persistence.Repositories.User,
  AuthenticationService.Domain.Repositories.User.Intf,
  AuthenticationService.Domain.Entities.UserStatus,
  AuthenticationService.Domain.UseCases.ChangeActiveStatus,
  AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf;

type
  EAuthenticationServiceIntegrationApiServersChangeActiveStatusV1Tests = class(EFidoException);

  [TestFixture]
  TAuthenticationServiceIntegrationApiServersChangeActiveStatusV1Tests = class
  public
    [Test]
    [TestCase('Activate', '{A6091D8C-21B4-40D8-B753-5800E2234B92},True')]
    [TestCase('Deactivate', '{A6091D8C-21B4-40D8-B753-5800E2234B92},False')]
    procedure ExecuteDoesNotRaiseExceptionWhenUserIsUpdated(const Id: string; const Active: string);

    [Test]
    [TestCase('Activate', '{A6091D8C-21B4-40D8-B753-5800E2234B92},True')]
    [TestCase('Deactivate', '{A6091D8C-21B4-40D8-B753-5800E2234B92},False')]
    procedure ExecuteRaisesEChangeActiveStatusUseCaseFailureWhenUserIsNotFound(const Id: string; const Active: string);

    [Test]
    [TestCase('Activate', '{A6091D8C-21B4-40D8-B753-5800E2234B92},True')]
    [TestCase('Deactivate', '{A6091D8C-21B4-40D8-B753-5800E2234B92},False')]
    procedure ExecuteRaisesEChangeActiveStatusUseCaseFailureWhenUpdateFails(const Id: string; const Active: string);
  end;

implementation

{ TAuthenticationServiceIntegrationApiServersChangeActiveStatusV1Tests }

procedure TAuthenticationServiceIntegrationApiServersChangeActiveStatusV1Tests.ExecuteDoesNotRaiseExceptionWhenUserIsUpdated(const Id: string; const Active: string);
var
  Resource: Shared<TChangeActiveStatusV1ApiServerController>;
  UseCase: IChangeActiveStatusUseCase;
  Repository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;

  Logger: Mock<ILogger>;

  UserId: TGuid;
  NewStatus: Boolean;
  UserStatus: Shared<TUserStatus>;
begin
  UserId := TGuid.Create(Id);
  NewStatus := StrToBool(Active);
  UserStatus := TUserStatus.Create(UserId, NewStatus);

  Logger := Mock<ILogger>.Create;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  UpdateStatusCommand.Setup.Returns<Integer>(1).When.Execute(UserId.ToString, Utilities.IfThen<Integer>(NewStatus, 1, 0));

  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  Repository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  UseCase := TChangeActiveStatusUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Resource := TChangeActiveStatusV1ApiServerController.Create(UseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Resource.Value.Execute(UserId, NewStatus);
    end);

  UpdateStatusCommand.Received(Times.Once).Execute(UserStatus.Value.Id.ToString, Utilities.IfThen<Integer>(NewStatus, 1, 0));
  UpdateStatusCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserStatus.Value.Id.ToString]), Arg.IsNotIn<Integer>([Utilities.IfThen<Integer>(NewStatus, 1, 0)]));
  GetUserQuery.Received(Times.Never).Open(Arg.IsAny<string>, Arg.IsAny<string>);
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>);
end;

procedure TAuthenticationServiceIntegrationApiServersChangeActiveStatusV1Tests.ExecuteRaisesEChangeActiveStatusUseCaseFailureWhenUpdateFails(const Id: string; const Active: string);
var
  Resource: Shared<TChangeActiveStatusV1ApiServerController>;
  UseCase: IChangeActiveStatusUseCase;
  Repository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;

  Logger: Mock<ILogger>;

  UserId: TGuid;
  NewStatus: Boolean;
  UserStatus: Shared<TUserStatus>;
begin
  UserId := TGuid.Create(Id);
  NewStatus := StrToBool(Active);
  UserStatus := TUserStatus.Create(UserId, NewStatus);

  Logger := Mock<ILogger>.Create;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  UpdateStatusCommand.Setup.Raises<EAuthenticationServiceIntegrationApiServersChangeActiveStatusV1Tests>.When.Execute(UserId.ToString, Utilities.IfThen<Integer>(NewStatus, 1, 0));

  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  Repository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  UseCase := TChangeActiveStatusUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Resource := TChangeActiveStatusV1ApiServerController.Create(UseCase);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(UserId, NewStatus);
    end,
    EChangeActiveStatusUseCaseFailure);

  UpdateStatusCommand.Received(Times.Once).Execute(UserStatus.Value.Id.ToString, Utilities.IfThen<Integer>(NewStatus, 1, 0));
  UpdateStatusCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserStatus.Value.Id.ToString]), Arg.IsNotIn<Integer>([Utilities.IfThen<Integer>(NewStatus, 1, 0)]));
  GetUserQuery.Received(Times.Never).Open(Arg.IsAny<string>, Arg.IsAny<string>);
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>);
end;

procedure TAuthenticationServiceIntegrationApiServersChangeActiveStatusV1Tests.ExecuteRaisesEChangeActiveStatusUseCaseFailureWhenUserIsNotFound(const Id: string; const Active: string);
var
  Resource: Shared<TChangeActiveStatusV1ApiServerController>;
  UseCase: IChangeActiveStatusUseCase;
  Repository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;

  Logger: Mock<ILogger>;

  UserId: TGuid;
  NewStatus: Boolean;
  UserStatus: Shared<TUserStatus>;
begin
  UserId := TGuid.Create(Id);
  NewStatus := StrToBool(Active);
  UserStatus := TUserStatus.Create(UserId, NewStatus);

  Logger := Mock<ILogger>.Create;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  UpdateStatusCommand.Setup.Returns<Integer>(0).When.Execute(UserId.ToString, Utilities.IfThen<Integer>(NewStatus, 1, 0));

  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  Repository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  UseCase := TChangeActiveStatusUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Resource := TChangeActiveStatusV1ApiServerController.Create(UseCase);

  Assert.WillRaise(
    procedure
    begin
      Resource.Value.Execute(UserId, NewStatus);
    end,
    EChangeActiveStatusUseCaseFailure);

  UpdateStatusCommand.Received(Times.Once).Execute(UserStatus.Value.Id.ToString, Utilities.IfThen<Integer>(NewStatus, 1, 0));
  UpdateStatusCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserStatus.Value.Id.ToString]), Arg.IsNotIn<Integer>([Utilities.IfThen<Integer>(NewStatus, 1, 0)]));
  GetUserQuery.Received(Times.Never).Open(Arg.IsAny<string>, Arg.IsAny<string>);
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>);
end;

initialization
  TDUnitX.RegisterTestFixture(TAuthenticationServiceIntegrationApiServersChangeActiveStatusV1Tests);

end.
