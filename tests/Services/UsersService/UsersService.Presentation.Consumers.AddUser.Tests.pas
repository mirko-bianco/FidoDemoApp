unit UsersService.Presentation.Consumers.AddUser.Tests;

interface

uses
  System.SysUtils,

  DUnitX.TestFramework,

  Spring,
  Spring.Logging,
  Spring.Mocking,

  Fido.Functional,
  Fido.Utilities,
  Fido.Exceptions,
  Fido.Types,
  Fido.Testing.Mock.Utils,
  Fido.JSON.Marshalling,
  Fido.EventsDriven.Publisher.Intf,

  UsersService.Presentation.Consumers.AddUser,
  UsersService.Persistence.Db.Types,
  UsersService.Persistence.Db.Add.Intf,
  UsersService.Persistence.Gateways.Add.Intf,
  UsersService.Persistence.Gateways.Add,
  UsersService.Persistence.Db.Remove.Intf,
  UsersService.Persistence.Gateways.Remove.Intf,
  UsersService.Persistence.Gateways.Remove,
  UsersService.Persistence.Db.GetAll.Intf,
  UsersService.Persistence.Gateways.GetAll.Intf,
  UsersService.Persistence.Gateways.GetAll,
  UsersService.Persistence.Db.GetCount.Intf,
  UsersService.Persistence.Gateways.GetCount.Intf,
  UsersService.Persistence.Gateways.GetCount,
  UsersService.Persistence.Repositories.User,
  UsersService.Domain.Repositories.User.Intf,
  UsersService.Domain.UseCases.Add,
  UsersService.Domain.UseCases.Add.Intf,
  UsersService.Domain.Entities.User;

type
  EUsersServiceAdaptersControllersConsumersAddUserTests = class(EFidoException);

  [TestFixture]
  TUsersServiceAdaptersControllersConsumersAddUserTests = class
  public
    [Test]
    procedure RunPublishesASuccessEventWhenUserCanBeAdded;

    [Test]
    [TestCase('Zero Records', '0')]
    [TestCase('Two Records', '2')]
    procedure RunPublishesAnErrorEventWhenXRecordsAreAffected(const AffectedRecords: Integer);

    [Test]
    procedure RunPublishesAnErrorEventWhenGatewayReturnsAnError;

    [Test]
    [TestCase('Invalid Id', 'werwer,First name, last name')]
    [TestCase('Empty Id', ',First name, last name')]
    [TestCase('Empty First Name', 'E970C2A4-135A-46B4-97F7-3FA2C88339EE,,last name')]
    [TestCase('Empty Last Name', 'E970C2A4-135A-46B4-97F7-3FA2C88339EE,first name,')]
    procedure RunPublishesAnErrorEventWhenDataIsInvalid(const UserId: string; const FirstName: string; const LastName: string);
  end;

implementation

{ TUsersServiceAdaptersControllersConsumersAddUserTests }

procedure TUsersServiceAdaptersControllersConsumersAddUserTests.RunPublishesASuccessEventWhenUserCanBeAdded;
var
  Consumer: Shared<TAddUserConsumerController>;
  UseCase: IAddUseCase;
  Repository: IUserRepository;
  InsertGateway: IInsertGateway;
  DeleteUserGateway: IDeleteUserGateway;
  GetAllUsersGateway: IGetAllUsersGateway;
  GetUsersCountGateway: IGetUsersCountGateway;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  GetAllUsersQuery: Mock<IGetAllUsersQuery>;
  GetUsersCountQuery: Mock<IGetUsersCountQuery>;

  Logger: Mock<ILogger>;

  Publisher: Mock<IEventsDrivenPublisher<string>>;

  UserId: TGuid;
  FirstName: string;
  LastName: string;
begin
  UserId := MockUtils.SomeGuid;
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Logger := Mock<ILogger>.Create;

  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  InsertUserCommand.Setup.Returns<Integer>(1).When.Execute(UserId.ToString, FirstName, LastName);

  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  GetAllUsersQuery := Mock<IGetAllUsersQuery>.Create;
  GetUsersCountQuery := Mock<IGetUsersCountQuery>.Create;

  InsertGateway := TInsertGateway.Create(InsertUserCommand);
  DeleteUserGateway := TDeleteUserGateway.Create(DeleteUserCommand);
  GetAllUsersGateway := TGetAllUsersGateway.Create(GetAllUsersQuery);
  GetUsersCountGateway := TGetUsersCountGateway.Create(GetUsersCountQuery);

  Repository := TUserRepository.Create(InsertGateway, DeleteUserGateway, GetAllUsersGateway, GetUsersCountGateway);

  UseCase := TAddUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Consumer := TAddUserConsumerController.Create(
    Logger,
    UseCase,
    Publisher);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Consumer.Value.Run(
        JSONUnmarshaller.To<IUserCreatedDto>(Format('{"userid": %s, "firstname": "%s", "lastname": "%s"}', [JSONMarshaller.From<TGuid>(UserId) , FirstName, LastName])));
    end);

  InsertUserCommand.Received(Times.Once).Execute(UserId.ToString , FirstName, LastName);
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserId.ToString]), Arg.IsNotIn<string>([FirstName]), Arg.IsNotIn<string>([LastName]));
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>);
  GetAllUsersQuery.Received(Times.Never).Open(Arg.IsAny<string>, Arg.IsAny<Integer>, Arg.IsAny<Integer>);
  GetUsersCountQuery.Received(Times.Never).Open;

  Publisher.Received(Times.Once).Trigger('Users', 'UserAdded', JSONMarshaller.From(UserId).DeQuotedString('"'));
  Publisher.Received(Times.Never).Trigger(Arg.IsNotIn<string>(['Users']), Arg.IsNotIn<string>(['UserAdded']), Arg.IsNotIn<string>([JSONMarshaller.From(UserId).DeQuotedString('"')]));
end;

procedure TUsersServiceAdaptersControllersConsumersAddUserTests.RunPublishesAnErrorEventWhenDataIsInvalid(const UserId, FirstName, LastName: string);
var
  Consumer: Shared<TAddUserConsumerController>;
  UseCase: IAddUseCase;
  Repository: IUserRepository;
  InsertGateway: IInsertGateway;
  DeleteUserGateway: IDeleteUserGateway;
  GetAllUsersGateway: IGetAllUsersGateway;
  GetUsersCountGateway: IGetUsersCountGateway;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  GetAllUsersQuery: Mock<IGetAllUsersQuery>;
  GetUsersCountQuery: Mock<IGetUsersCountQuery>;

  Logger: Mock<ILogger>;

  Publisher: Mock<IEventsDrivenPublisher<string>>;
  Id: TGuid;
begin
  Logger := Mock<ILogger>.Create;

  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  GetAllUsersQuery := Mock<IGetAllUsersQuery>.Create;
  GetUsersCountQuery := Mock<IGetUsersCountQuery>.Create;

  InsertGateway := TInsertGateway.Create(InsertUserCommand);
  DeleteUserGateway := TDeleteUserGateway.Create(DeleteUserCommand);
  GetAllUsersGateway := TGetAllUsersGateway.Create(GetAllUsersQuery);
  GetUsersCountGateway := TGetUsersCountGateway.Create(GetUsersCountQuery);

  Repository := TUserRepository.Create(InsertGateway, DeleteUserGateway, GetAllUsersGateway, GetUsersCountGateway);

  UseCase := TAddUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Consumer := TAddUserConsumerController.Create(
    Logger,
    UseCase,
    Publisher);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Consumer.Value.Run(
        JSONUnmarshaller.To<IUserCreatedDto>(Format('{"userid": "%s", "firstname": "%s", "lastname": "%s"}', [UserId , FirstName, LastName])));
    end);

  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>);
  GetAllUsersQuery.Received(Times.Never).Open(Arg.IsAny<string>, Arg.IsAny<Integer>, Arg.IsAny<Integer>);
  GetUsersCountQuery.Received(Times.Never).Open;

  if Utilities.TryStringToTGuid(Format('{%s}', [UserId]), Id) then
    Publisher.Received(Times.Once).Trigger('Users', 'UserAddFailed', UserId)
  else
    Publisher.Received(Times.Once).Trigger('Users', 'UserAddFailed', '00000000-0000-0000-0000-000000000000');
  Publisher.Received(Times.Never).Trigger(Arg.IsNotIn<string>(['Users']), Arg.IsNotIn<string>(['UserAddFailed']), Arg.IsNotIn<string>([UserId]));
end;

procedure TUsersServiceAdaptersControllersConsumersAddUserTests.RunPublishesAnErrorEventWhenGatewayReturnsAnError;
var
  Consumer: Shared<TAddUserConsumerController>;
  UseCase: IAddUseCase;
  Repository: IUserRepository;
  InsertGateway: IInsertGateway;
  DeleteUserGateway: IDeleteUserGateway;
  GetAllUsersGateway: IGetAllUsersGateway;
  GetUsersCountGateway: IGetUsersCountGateway;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  GetAllUsersQuery: Mock<IGetAllUsersQuery>;
  GetUsersCountQuery: Mock<IGetUsersCountQuery>;

  Logger: Mock<ILogger>;

  Publisher: Mock<IEventsDrivenPublisher<string>>;

  UserId: TGuid;
  FirstName: string;
  LastName: string;
begin
  UserId := MockUtils.SomeGuid;
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Logger := Mock<ILogger>.Create;

  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  InsertUserCommand.Setup.Raises<EUsersServiceAdaptersControllersConsumersAddUserTests>.When.Execute(UserId.ToString, FirstName, LastName);

  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  GetAllUsersQuery := Mock<IGetAllUsersQuery>.Create;
  GetUsersCountQuery := Mock<IGetUsersCountQuery>.Create;

  InsertGateway := TInsertGateway.Create(InsertUserCommand);
  DeleteUserGateway := TDeleteUserGateway.Create(DeleteUserCommand);
  GetAllUsersGateway := TGetAllUsersGateway.Create(GetAllUsersQuery);
  GetUsersCountGateway := TGetUsersCountGateway.Create(GetUsersCountQuery);

  Repository := TUserRepository.Create(InsertGateway, DeleteUserGateway, GetAllUsersGateway, GetUsersCountGateway);

  UseCase := TAddUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Consumer := TAddUserConsumerController.Create(
    Logger,
    UseCase,
    Publisher);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Consumer.Value.Run(
        JSONUnmarshaller.To<IUserCreatedDto>(Format('{"userid": %s, "firstname": "%s", "lastname": "%s"}', [JSONMarshaller.From<TGuid>(UserId) , FirstName, LastName])));
    end);

  InsertUserCommand.Received(Times.Once).Execute(UserId.ToString , FirstName, LastName);
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserId.ToString]), Arg.IsNotIn<string>([FirstName]), Arg.IsNotIn<string>([LastName]));
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>);
  GetAllUsersQuery.Received(Times.Never).Open(Arg.IsAny<string>, Arg.IsAny<Integer>, Arg.IsAny<Integer>);
  GetUsersCountQuery.Received(Times.Never).Open;

  Publisher.Received(Times.Once).Trigger('Users', 'UserAddFailed', JSONMarshaller.From(UserId).DeQuotedString('"'));
  Publisher.Received(Times.Never).Trigger(Arg.IsNotIn<string>(['Users']), Arg.IsNotIn<string>(['UserAddFailed']), Arg.IsNotIn<string>([JSONMarshaller.From(UserId).DeQuotedString('"')]));
end;

procedure TUsersServiceAdaptersControllersConsumersAddUserTests.RunPublishesAnErrorEventWhenXRecordsAreAffected(const AffectedRecords: Integer);
var
  Consumer: Shared<TAddUserConsumerController>;
  UseCase: IAddUseCase;
  Repository: IUserRepository;
  InsertGateway: IInsertGateway;
  DeleteUserGateway: IDeleteUserGateway;
  GetAllUsersGateway: IGetAllUsersGateway;
  GetUsersCountGateway: IGetUsersCountGateway;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  GetAllUsersQuery: Mock<IGetAllUsersQuery>;
  GetUsersCountQuery: Mock<IGetUsersCountQuery>;

  Logger: Mock<ILogger>;

  Publisher: Mock<IEventsDrivenPublisher<string>>;

  UserId: TGuid;
  FirstName: string;
  LastName: string;
begin
  UserId := MockUtils.SomeGuid;
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Logger := Mock<ILogger>.Create;

  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  InsertUserCommand.Setup.Returns<Integer>(AffectedRecords).When.Execute(UserId.ToString, FirstName, LastName);

  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  GetAllUsersQuery := Mock<IGetAllUsersQuery>.Create;
  GetUsersCountQuery := Mock<IGetUsersCountQuery>.Create;

  InsertGateway := TInsertGateway.Create(InsertUserCommand);
  DeleteUserGateway := TDeleteUserGateway.Create(DeleteUserCommand);
  GetAllUsersGateway := TGetAllUsersGateway.Create(GetAllUsersQuery);
  GetUsersCountGateway := TGetUsersCountGateway.Create(GetUsersCountQuery);

  Repository := TUserRepository.Create(InsertGateway, DeleteUserGateway, GetAllUsersGateway, GetUsersCountGateway);

  UseCase := TAddUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Publisher := Mock<IEventsDrivenPublisher<string>>.Create;
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);

  Consumer := TAddUserConsumerController.Create(
    Logger,
    UseCase,
    Publisher);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Consumer.Value.Run(
        JSONUnmarshaller.To<IUserCreatedDto>(Format('{"userid": %s, "firstname": "%s", "lastname": "%s"}', [JSONMarshaller.From<TGuid>(UserId) , FirstName, LastName])));
    end);

  InsertUserCommand.Received(Times.Once).Execute(UserId.ToString , FirstName, LastName);
  InsertUserCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserId.ToString]), Arg.IsNotIn<string>([FirstName]), Arg.IsNotIn<string>([LastName]));
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>);
  GetAllUsersQuery.Received(Times.Never).Open(Arg.IsAny<string>, Arg.IsAny<Integer>, Arg.IsAny<Integer>);
  GetUsersCountQuery.Received(Times.Never).Open;

  Publisher.Received(Times.Once).Trigger('Users', 'UserAddFailed', JSONMarshaller.From(UserId).DeQuotedString('"'));
  Publisher.Received(Times.Never).Trigger(Arg.IsNotIn<string>(['Users']), Arg.IsNotIn<string>(['UserAddFailed']), Arg.IsNotIn<string>([JSONMarshaller.From(UserId).DeQuotedString('"')]));
end;

initialization
  TDUnitX.RegisterTestFixture(TUsersServiceAdaptersControllersConsumersAddUserTests);

end.
