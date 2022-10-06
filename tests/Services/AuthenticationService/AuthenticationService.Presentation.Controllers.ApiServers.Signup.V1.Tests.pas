unit AuthenticationService.Presentation.Controllers.ApiServers.Signup.V1.Tests;

interface

uses
  System.SysUtils,
  System.Hash,

  DUnitX.TestFramework,

  Spring,
  Spring.Logging,
  Spring.Mocking,

  Fido.Functional,
  Fido.Exceptions,
  Fido.Types,
  Fido.Testing.Mock.Utils,
  Fido.JSON.Marshalling,
  Fido.Api.Server.Exceptions,
  Fido.EventsDriven.Publisher.Intf,

  AuthenticationService.Presentation.Controllers.ApiServers.Signup.V1,
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
  AuthenticationService.Domain.UseCases.Signup,
  AuthenticationService.Domain.UseCases.Signup.Intf,
  AuthenticationService.Domain.UseCases.Remove,
  AuthenticationService.Domain.UseCases.Remove.Intf;

type
  EAuthenticationServiceIntegrationApiServersSignupV1Tests = class(EFidoException);

  [TestFixture]
  TAuthenticationServiceIntegrationApiServersSignupV1Tests = class
  public
    [Test]
    procedure ExecuteReturnsIdWhenNoExceptionIsRaised;

    [Test]
    [TestCase('No Username', ',This&That2022wrtewrwergwer,FirstName,LastName')]
    [TestCase('No Password', 'Username,,FirstName,LastName')]
    [TestCase('No Firstname', 'Username,This&That2022wrtewrwergwer,,LastName')]
    [TestCase('No Lastname', 'Username,This&That2022wrtewrwergwer,FirstName,')]
    procedure ExecuteRaisesEApiServer400WhenDataIsNotCorrect(const Username: string; const Password: string; const FirstName: string; const LastName: string);

    [Test]
    procedure ExecuteRaisesEApiServer500WhenUserCannotBeStored;

    [Test]
    procedure ExecuteRaisesEApiServer500WhenDatabaseRaisesAnError;

    [Test]
    procedure ExecuteRaisesEApiServer500WhenCannotPublishEvent;

    [Test]
    procedure ExecuteRaisesEApiServer500WhenUserCannotBeRemovedAfterException;

    [Test]
    procedure ExecuteRaisesEApiServer500WhenUserCannotBeRemovedBecauseItIsNotFound;
  end;

implementation

{ TAuthenticationServiceAdaptersControllersApiServersSignupV1Tests }

procedure TAuthenticationServiceIntegrationApiServersSignupV1Tests.ExecuteRaisesEApiServer400WhenDataIsNotCorrect(
  const Username: string;
  const Password: string;
  const FirstName: string;
  const LastName: string);
var
  Resource: Shared<TSignupV1ApiServerController>;

  Logger: Mock<ILogger>;
  Signup: ISignupUseCase;
  UserRepository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  InsertUserCommand: Mock<IInsertUserCommand>;

  Remove: IRemoveUseCase;
  Publisher: Mock<IEventsDrivenPublisher<string>>;

  User: Shared<TUser>;
begin
  User := TUSer.Create(Username, Password);

  Logger := Mock<ILogger>.Create;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  InsertUserCommand.Setup.Returns<Integer>(1).When.Execute(Arg.IsAny<string>, Arg.IsIn<string>(Username), Arg.IsIn<string>(THashMD5.GetHashString(Password)));
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  UserRepository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  Signup := TSignupUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Remove := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Resource := TSignupV1ApiServerController.Create(
    Logger,
    Signup,
    Remove,
    Publisher);

  Assert.WillRaise(
    procedure
    var
      Result: TGuid;
    begin
      Result := Resource.Value.Execute(
        JSONUnmarshaller.To<ISignupParams>(
          Format(
            '{"username": "%s", "password": "%s", "firstname": "%s", "lastname": "%s"}',
            [Username,
             Password,
             FirstName,
             LastName])));
    end,
    EApiServer400);

  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  Publisher.Received(Times.Never).Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
end;

procedure TAuthenticationServiceIntegrationApiServersSignupV1Tests.ExecuteRaisesEApiServer500WhenCannotPublishEvent;
var
  Resource: Shared<TSignupV1ApiServerController>;

  Logger: Mock<ILogger>;
  Signup: ISignupUseCase;
  UserRepository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  InsertUserCommand: Mock<IInsertUserCommand>;

  Remove: IRemoveUseCase;
  Publisher: Mock<IEventsDrivenPublisher<string>>;

  Username: string;
  Password: string;
  User: Shared<TUser>;
  FirstName: string;
  LastName: string;
begin
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdnsdngsdfgnkl';
  User := TUSer.Create(Username, Password);
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Logger := Mock<ILogger>.Create;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  InsertUserCommand.Setup.Returns<Integer>(1).When.Execute(Arg.IsAny<string>, Arg.IsIn<string>(Username), Arg.IsIn<string>(THashMD5.GetHashString(Password)));
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  DeleteUserCommand.Setup.Returns<Integer>(1).When.Execute(Arg.IsAny<string>);

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  UserRepository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  Signup := TSignupUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Remove := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(False).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Resource := TSignupV1ApiServerController.Create(
    Logger,
    Signup,
    Remove,
    Publisher);

  Assert.WillRaise(
    procedure
    var
      Result: TGuid;
    begin
      Result := Resource.Value.Execute(
        JSONUnmarshaller.To<ISignupParams>(
          Format(
            '{"username": "%s", "password": "%s", "firstname": "%s", "lastname": "%s"}',
            [Username,
             Password,
             FirstName,
             LastName])));
    end,
    EApiServer500);

  InsertUserCommand.Received(Times.Once).Execute(Arg.IsAny<string>, Arg.IsIn<string>([Username]), Arg.IsIn<string>([THashMD5.GetHashString(Password)]));
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsNotIn<string>([Username]), Arg.IsNotIn<string>([THashMD5.GetHashString(Password)]));
  DeleteUserCommand.Received(Times.Once).Execute(Arg.IsAny<string>);
  Publisher.Received(Times.Once).Trigger(Arg.IsIn<string>(['Authentication']), Arg.IsIn<string>(['UserAdded']), Arg.IsAny<string>);
  Publisher.Received(Times.Never).Trigger(Arg.IsNotIn<string>(['Authentication']), Arg.IsNotIn<string>(['UserAdded']), Arg.IsAny<string>);
end;

procedure TAuthenticationServiceIntegrationApiServersSignupV1Tests.ExecuteRaisesEApiServer500WhenDatabaseRaisesAnError;
var
  Resource: Shared<TSignupV1ApiServerController>;

  Logger: Mock<ILogger>;
  Signup: ISignupUseCase;
  UserRepository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  InsertUserCommand: Mock<IInsertUserCommand>;

  Remove: IRemoveUseCase;
  Publisher: Mock<IEventsDrivenPublisher<string>>;

  Username: string;
  Password: string;
  User: Shared<TUser>;
  FirstName: string;
  LastName: string;
begin
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdnsdngsdfgnkl';
  User := TUSer.Create(Username, Password);
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Logger := Mock<ILogger>.Create;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  InsertUserCommand.Setup.Raises<EAuthenticationServiceIntegrationApiServersSignupV1Tests>.When.Execute(Arg.IsAny<string>, Arg.IsIn<string>(Username), Arg.IsIn<string>(THashMD5.GetHashString(Password)));
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  UserRepository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  Signup := TSignupUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Remove := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Resource := TSignupV1ApiServerController.Create(
    Logger,
    Signup,
    Remove,
    Publisher);

  Assert.WillRaise(
    procedure
    var
      SignupParams: ISignupParams;
      Result: TGuid;
    begin
      SignupParams := JSONUnmarshaller.To<ISignupParams>(
        Format(
          '{"username": "%s", "password": "%s", "firstname": "%s", "lastname": "%s"}',
          [Username,
           Password,
           FirstName,
           LastName]));
      Result := Resource.Value.Execute(SignupParams);
    end,
    EApiServer500);

  InsertUserCommand.Received(Times.Once).Execute(Arg.IsAny<string>, Arg.IsIn<string>([Username]), Arg.IsIn<string>([THashMD5.GetHashString(Password)]));
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsNotIn<string>([Username]), Arg.IsNotIn<string>([THashMD5.GetHashString(Password)]));
  Publisher.Received(Times.Never).Trigger(Arg.IsIn<string>(['Authentication']), Arg.IsIn<string>(['UserAdded']), Arg.IsAny<string>);
end;

procedure TAuthenticationServiceIntegrationApiServersSignupV1Tests.ExecuteRaisesEApiServer500WhenUserCannotBeRemovedAfterException;
var
  Resource: Shared<TSignupV1ApiServerController>;

  Logger: Mock<ILogger>;
  Signup: ISignupUseCase;
  UserRepository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  InsertUserCommand: Mock<IInsertUserCommand>;

  Remove: IRemoveUseCase;
  Publisher: Mock<IEventsDrivenPublisher<string>>;

  Username: string;
  Password: string;
  User: Shared<TUser>;
  FirstName: string;
  LastName: string;
begin
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdnsdngsdfgnkl';
  User := TUSer.Create(Username, Password);
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Logger := Mock<ILogger>.Create;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  InsertUserCommand.Setup.Returns<Integer>(1).When.Execute(Arg.IsAny<string>, Arg.IsIn<string>(Username), Arg.IsIn<string>(THashMD5.GetHashString(Password)));
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  DeleteUserCommand.Setup.Raises<EAuthenticationServiceIntegrationApiServersSignupV1Tests>.When.Execute(Arg.IsAny<string>);

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  UserRepository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  Signup := TSignupUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Remove := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(False).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Resource := TSignupV1ApiServerController.Create(
    Logger,
    Signup,
    Remove,
    Publisher);

  Assert.WillRaise(
    procedure
    var
      Result: TGuid;
    begin
      Result := Resource.Value.Execute(
        JSONUnmarshaller.To<ISignupParams>(
          Format(
            '{"username": "%s", "password": "%s", "firstname": "%s", "lastname": "%s"}',
            [Username,
             Password,
             FirstName,
             LastName])));
    end,
    EApiServer500);

  InsertUserCommand.Received(Times.Once).Execute(Arg.IsAny<string>, Arg.IsIn<string>([Username]), Arg.IsIn<string>([THashMD5.GetHashString(Password)]));
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsNotIn<string>([Username]), Arg.IsNotIn<string>([THashMD5.GetHashString(Password)]));
  Publisher.Received(Times.Once).Trigger(Arg.IsIn<string>(['Authentication']), Arg.IsIn<string>(['UserAdded']), Arg.IsAny<string>);
  Publisher.Received(Times.Never).Trigger(Arg.IsNotIn<string>(['Authentication']), Arg.IsNotIn<string>(['UserAdded']), Arg.IsAny<string>);
end;

procedure TAuthenticationServiceIntegrationApiServersSignupV1Tests.ExecuteRaisesEApiServer500WhenUserCannotBeRemovedBecauseItIsNotFound;
var
  Resource: Shared<TSignupV1ApiServerController>;

  Logger: Mock<ILogger>;
  Signup: ISignupUseCase;
  UserRepository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  InsertUserCommand: Mock<IInsertUserCommand>;

  Remove: IRemoveUseCase;
  Publisher: Mock<IEventsDrivenPublisher<string>>;

  Username: string;
  Password: string;
  User: Shared<TUser>;
  FirstName: string;
  LastName: string;
begin
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdnsdngsdfgnkl';
  User := TUSer.Create(Username, Password);
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Logger := Mock<ILogger>.Create;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  InsertUserCommand.Setup.Returns<Integer>(1).When.Execute(Arg.IsAny<string>, Arg.IsIn<string>(Username), Arg.IsIn<string>(THashMD5.GetHashString(Password)));
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  DeleteUserCommand.Setup.Returns<Integer>(0).When.Execute(Arg.IsAny<string>);

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  UserRepository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  Signup := TSignupUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Remove := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(False).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Resource := TSignupV1ApiServerController.Create(
    Logger,
    Signup,
    Remove,
    Publisher);

  Assert.WillRaise(
    procedure
    var
      Result: TGuid;
    begin
      Result := Resource.Value.Execute(
        JSONUnmarshaller.To<ISignupParams>(
          Format(
            '{"username": "%s", "password": "%s", "firstname": "%s", "lastname": "%s"}',
            [Username,
             Password,
             FirstName,
             LastName])));
    end,
    EApiServer500);

  InsertUserCommand.Received(Times.Once).Execute(Arg.IsAny<string>, Arg.IsIn<string>([Username]), Arg.IsIn<string>([THashMD5.GetHashString(Password)]));
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsNotIn<string>([Username]), Arg.IsNotIn<string>([THashMD5.GetHashString(Password)]));
  Publisher.Received(Times.Once).Trigger(Arg.IsIn<string>(['Authentication']), Arg.IsIn<string>(['UserAdded']), Arg.IsAny<string>);
  Publisher.Received(Times.Never).Trigger(Arg.IsNotIn<string>(['Authentication']), Arg.IsNotIn<string>(['UserAdded']), Arg.IsAny<string>);
end;

procedure TAuthenticationServiceIntegrationApiServersSignupV1Tests.ExecuteRaisesEApiServer500WhenUserCannotBeStored;
var
  Resource: Shared<TSignupV1ApiServerController>;

  Logger: Mock<ILogger>;
  Signup: ISignupUseCase;
  UserRepository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  InsertUserCommand: Mock<IInsertUserCommand>;

  Remove: IRemoveUseCase;
  Publisher: Mock<IEventsDrivenPublisher<string>>;

  Username: string;
  Password: string;
  User: Shared<TUser>;
  FirstName: string;
  LastName: string;
begin
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdnsdngsdfgnkl';
  User := TUSer.Create(Username, Password);
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Logger := Mock<ILogger>.Create;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  InsertUserCommand.Setup.Returns<Integer>(0).When.Execute(Arg.IsAny<string>, Arg.IsIn<string>(Username), Arg.IsIn<string>(THashMD5.GetHashString(Password)));
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  UserRepository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  Signup := TSignupUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Remove := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Resource := TSignupV1ApiServerController.Create(
    Logger,
    Signup,
    Remove,
    Publisher);

  Assert.WillRaise(
    procedure
    var
      SignupParams: ISignupParams;
      Result: TGuid;
    begin
      SignupParams := JSONUnmarshaller.To<ISignupParams>(
        Format(
          '{"username": "%s", "password": "%s", "firstname": "%s", "lastname": "%s"}',
          [Username,
           Password,
           FirstName,
           LastName]));
      Result := Resource.Value.Execute(SignupParams);
    end,
    EApiServer500);

  InsertUserCommand.Received(Times.Once).Execute(Arg.IsAny<string>, Arg.IsIn<string>([Username]), Arg.IsIn<string>([THashMD5.GetHashString(Password)]));
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsNotIn<string>([Username]), Arg.IsNotIn<string>([THashMD5.GetHashString(Password)]));
  Publisher.Received(Times.Never).Trigger(Arg.IsIn<string>(['Authentication']), Arg.IsIn<string>(['UserAdded']), Arg.IsAny<string>);
end;

procedure TAuthenticationServiceIntegrationApiServersSignupV1Tests.ExecuteReturnsIdWhenNoExceptionIsRaised;
var
  Resource: Shared<TSignupV1ApiServerController>;

  Logger: Mock<ILogger>;
  Signup: ISignupUseCase;
  UserRepository: IUserRepository;
  ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  LoginGateway: ILoginGateway;
  RemoveGateway: IRemoveGateway;
  SignupGateway: ISignupGateway;
  UpdateStatusCommand: Mock<IUpdateActiveStatusCommand>;
  GetUserQuery: Mock<IGetUserByUsernameAndHashedPasswordQuery>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  InsertUserCommand: Mock<IInsertUserCommand>;

  Remove: IRemoveUseCase;
  Publisher: Mock<IEventsDrivenPublisher<string>>;

  Username: string;
  Password: string;
  User: Shared<TUser>;
  FirstName: string;
  LastName: string;

  Result: TGuid;
begin
  Username := MockUtils.SomeString;
  Password := 'This&That2022fsdnsdngsdfgnkl';
  User := TUSer.Create(Username, Password);
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Logger := Mock<ILogger>.Create;

  UpdateStatusCommand := Mock<IUpdateActiveStatusCommand>.Create;
  GetUserQuery := Mock<IGetUserByUsernameAndHashedPasswordQuery>.Create;
  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  InsertUserCommand.Setup.Returns<Integer>(1).When.Execute(Arg.IsAny<string>, Arg.IsIn<string>(Username), Arg.IsIn<string>(THashMD5.GetHashString(Password)));
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;

  ChangeActiveStatusGateway := TChangeActiveStatusGateway.Create(UpdateStatusCommand);
  LoginGateway := TLoginGateway.Create(GetUserQuery);
  RemoveGateway := TRemoveGateway.Create(DeleteUserCommand);
  SignupGateway := TSignupGateway.Create(InsertUserCommand);

  UserRepository := TUserRepository.Create(ChangeActiveStatusGateway, LoginGateway, RemoveGateway, SignupGateway);

  Signup := TSignupUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Remove := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := UserRepository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Resource := TSignupV1ApiServerController.Create(
    Logger,
    Signup,
    Remove,
    Publisher);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Result := Resource.Value.Execute(
        JSONUnmarshaller.To<ISignupParams>(
          Format(
            '{"username": "%s", "password": "%s", "firstname": "%s", "lastname": "%s"}',
            [Username,
             Password,
             FirstName,
             LastName])));
    end);

  InsertUserCommand.Received(Times.Once).Execute(Arg.IsAny<string>, Arg.IsIn<string>([Username]), Arg.IsIn<string>([THashMD5.GetHashString(Password)]));
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsNotIn<string>([Username]), Arg.IsNotIn<string>([THashMD5.GetHashString(Password)]));
  Publisher.Received(Times.Once).Trigger(Arg.IsIn<string>(['Authentication']), Arg.IsIn<string>(['UserAdded']), Arg.IsAny<string>);
  Publisher.Received(Times.Never).Trigger(Arg.IsNotIn<string>(['Authentication']), Arg.IsNotIn<string>(['UserAdded']), Arg.IsAny<string>);
end;

initialization
  TDUnitX.RegisterTestFixture(TAuthenticationServiceIntegrationApiServersSignupV1Tests);

end.
