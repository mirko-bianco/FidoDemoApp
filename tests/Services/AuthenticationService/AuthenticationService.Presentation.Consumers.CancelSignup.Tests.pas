unit AuthenticationService.Presentation.Consumers.CancelSignup.Tests;

interface

uses
  System.SysUtils,

  DUnitX.TestFramework,

  Spring,
  Spring.Logging,
  Spring.Mocking,

  Fido.Exceptions,
  Fido.Types,
  Fido.Testing.Mock.Utils,

  AuthenticationService.Presentation.Consumers.CancelSignup,
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
  AuthenticationService.Domain.Entities.User,
  AuthenticationService.Domain.Usecases.Types,
  AuthenticationService.Domain.UseCases.Remove,
  AuthenticationService.Domain.UseCases.Remove.Intf;

type
  EAuthenticationServiceAdaptersControllersConsumersCancelSignupTests = class(EFidoException);

  [TestFixture]
  TAuthenticationServiceAdaptersControllersConsumersCancelSignupTests = class
  public
    [Test]
    procedure RunDoesNotRaiseAnyExceptionWhenSignupCanBeCanceled;

    [Test]
    procedure RunRaisesEUserRepositoryWhenSignupCannotBeCanceled;
  end;

implementation

{ TAuthenticationServiceAdaptersControllersConsumersCancelSignupTests }

procedure TAuthenticationServiceAdaptersControllersConsumersCancelSignupTests.RunRaisesEUserRepositoryWhenSignupCannotBeCanceled;
var
  Consumer: Shared<TCancelSignupConsumerController>;
  UseCase: IRemoveUsecase;
  UserRepository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  InsertUserCommand: Mock<IInsertUserCommand>;

  UserId: TGuid;
begin
  UserId := MockUtils.SomeGuid;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  DeleteUserCommand.Setup.Returns<Integer>(0).When.Execute(UserId.ToString);

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  UserRepository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  UseCase := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Consumer := TCancelSignupConsumerController.Create(UseCase);

  Assert.WillRaise(
    procedure
    begin
      Consumer.Value.Run(UserId);
    end,
    EUserRepository);

  DeleteUserCommand.Received(Times.Once).Execute(UserId.ToString);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserId.ToString]));
end;

procedure TAuthenticationServiceAdaptersControllersConsumersCancelSignupTests.RunDoesNotRaiseAnyExceptionWhenSignupCanBeCanceled;
var
  Consumer: Shared<TCancelSignupConsumerController>;
  UseCase: IRemoveUsecase;
  UserRepository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  InsertUserCommand: Mock<IInsertUserCommand>;

  UserId: TGuid;
begin
  UserId := MockUtils.SomeGuid;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  DeleteUserCommand.Setup.Returns<Integer>(1).When.Execute(UserId.ToString);

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  UserRepository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  UseCase := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Consumer := TCancelSignupConsumerController.Create(UseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Consumer.Value.Run(UserId);
    end);

  DeleteUserCommand.Received(Times.Once).Execute(UserId.ToString);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserId.ToString]));
end;

initialization
  TDUnitX.RegisterTestFixture(TAuthenticationServiceAdaptersControllersConsumersCancelSignupTests);

end.

