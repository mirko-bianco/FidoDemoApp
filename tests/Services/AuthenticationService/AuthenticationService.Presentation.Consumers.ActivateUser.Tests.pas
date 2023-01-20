unit AuthenticationService.Presentation.Consumers.ActivateUser.Tests;

interface

uses
  System.SysUtils,

  DUnitX.TestFramework,

  Spring,
  Spring.Logging,
  Spring.Mocking,

  Fido.Exceptions,
  Fido.Functional,
  Fido.Types,
  Fido.Testing.Mock.Utils,
  Fido.JSON.Marshalling,
  Fido.EventsDriven.Publisher.Intf,

  AuthenticationService.Presentation.Consumers.ActivateUser,
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
  AuthenticationService.Domain.Usecases.Types,
  AuthenticationService.Domain.UseCases.ChangeActiveStatus,
  AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf;

type
  EAuthenticationServiceAdaptersControllersConsumersActivateUserTests = class(EFidoException);

  [TestFixture]
  TAuthenticationServiceAdaptersControllersConsumersActivateUserTests = class
  public
    [Test]
    procedure RunDoesNotRaiseAnyExceptionWhenUserIsUpdated;

    [Test]
    procedure RunRaisesEChangeActiveStatusUseCaseFailureAndTriggersFailedEventWhenUserCannotBeUpdated;
  end;

implementation

{ TAuthenticationServiceAdaptersControllersConsumersActivateUserTests }

procedure TAuthenticationServiceAdaptersControllersConsumersActivateUserTests.RunDoesNotRaiseAnyExceptionWhenUserIsUpdated;
var
  Consumer: Shared<TActivateUserConsumerController>;

  UseCase: IChangeActiveStatusUsecase;
  UserRepository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  InsertUserCommand: Mock<IInsertUserCommand>;

  Publisher: Mock<IEventsDrivenPublisher<string>>;

  UserId: TGuid;
begin
  UserId := MockUtils.SomeGuid;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  UpdateStatusCommand.Setup.Returns<Integer>(1).When.Execute(UserId.ToString, 1);

  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  UserRepository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  UseCase := TChangeActiveStatusUsecase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;

  Consumer := TActivateUserConsumerController.Create(
    UseCase,
    Publisher);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Consumer.Value.Run(UserId);
    end);

  UpdateStatusCommand.Received(Times.Once).Execute(UserId.ToString, 1);
  UpdateStatusCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserId.ToString]), Arg.IsNotIn<Integer>([1]));
  Publisher.Received(Times.Never).Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
end;

procedure TAuthenticationServiceAdaptersControllersConsumersActivateUserTests.RunRaisesEChangeActiveStatusUseCaseFailureAndTriggersFailedEventWhenUserCannotBeUpdated;
var
  Consumer: Shared<TActivateUserConsumerController>;

  UseCase: IChangeActiveStatusUsecase;
  UserRepository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  InsertUserCommand: Mock<IInsertUserCommand>;

  Publisher: Mock<IEventsDrivenPublisher<string>>;

  UserId: TGuid;
begin
  UserId := MockUtils.SomeGuid;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  UpdateStatusCommand.Setup.Raises<EAuthenticationServiceAdaptersControllersConsumersActivateUserTests>.When.Execute(UserId.ToString, 1);

  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  UserRepository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  UseCase := TChangeActiveStatusUsecase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Consumer := TActivateUserConsumerController.Create(
    UseCase,
    Publisher);

  Assert.WillRaise(
    procedure
    begin
      Consumer.Value.Run(UserId);
    end,
    EChangeActiveStatusUseCaseFailure);

  UpdateStatusCommand.Received(Times.Once).Execute(UserId.ToString, 1);
  UpdateStatusCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserId.ToString]), Arg.IsNotIn<Integer>([1]));
  Publisher.Received(Times.Once).Trigger(Arg.Isin<string>(['Authentication']), Arg.IsIn<string>(['UserActivationFailed']), Arg.IsAny<string>);
end;

initialization
  TDUnitX.RegisterTestFixture(TAuthenticationServiceAdaptersControllersConsumersActivateUserTests);

end.
