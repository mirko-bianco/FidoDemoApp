unit UsersService.Presentation.Consumers.RemoveUser.Tests;

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
  Fido.JSON.Marshalling,

  UsersService.Presentation.Consumers.RemoveUser,
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
  UsersService.Domain.UseCases.Remove,
  UsersService.Domain.UseCases.Remove.Intf;

type
  EAdaptersControllersConsumersRemoveUserTests = class(EFidoException);

  [TestFixture]
  TAdaptersControllersConsumersRemoveUserTests = class
  public
    [Test]
    procedure RunDoesNotRaiseAnyExceptionWhenUserCanBeDeleted;

    [Test]
    procedure RunDoesNotRaiseAnyExceptionWhenUserCannotBeDeletedBecauseIsNotInTheDatabase;

    [Test]
    procedure RunDoesNotRaiseAnyExceptionWhenUserCannotBeDeletedBecauseOfAnError;
  end;

implementation

{ TAdaptersControllersConsumersRemoveUserTests }

procedure TAdaptersControllersConsumersRemoveUserTests.RunDoesNotRaiseAnyExceptionWhenUserCannotBeDeletedBecauseIsNotInTheDatabase;
var
  Consumer: Shared<TRemoveUserConsumerController>;

  Logger: Mock<ILogger>;
  UseCase: IRemoveUseCase;
  Repository: IUserRepository;
  InsertGateway: IInsertGateway;
  DeleteUserGateway: IDeleteUserGateway;
  GetAllUsersGateway: IGetAllUsersGateway;
  GetUsersCountGateway: IGetUsersCountGateway;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  GetAllUsersQuery: Mock<IGetAllUsersQuery>;
  GetUsersCountQuery: Mock<IGetUsersCountQuery>;

  UserId: TGuid;
begin
  UserId := MockUtils.SomeGuid;

  Logger := Mock<ILogger>.Create;

  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  DeleteUserCommand.Setup.Returns<Integer>(0).When.Execute(UserId.ToString);

  GetAllUsersQuery := Mock<IGetAllUsersQuery>.Create;
  GetUsersCountQuery := Mock<IGetUsersCountQuery>.Create;

  InsertGateway := TInsertGateway.Create(InsertUserCommand);
  DeleteUserGateway := TDeleteUserGateway.Create(DeleteUserCommand);
  GetAllUsersGateway := TGetAllUsersGateway.Create(GetAllUsersQuery);
  GetUsersCountGateway := TGetUsersCountGateway.Create(GetUsersCountQuery);

  Repository := TUserRepository.Create(InsertGateway, DeleteUserGateway, GetAllUsersGateway, GetUsersCountGateway);

  UseCase := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Consumer := TRemoveUserConsumerController.Create(
    Logger,
    UseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Consumer.Value.Run(UserId);
    end);

  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  DeleteUserCommand.Received(Times.Once).Execute(UserId.ToString);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserId.ToString]));
  GetAllUsersQuery.Received(Times.Never).Open(Arg.IsAny<string>, Arg.IsAny<Integer>, Arg.IsAny<Integer>);
  GetUsersCountQuery.Received(Times.Never).Open;
end;

procedure TAdaptersControllersConsumersRemoveUserTests.RunDoesNotRaiseAnyExceptionWhenUserCannotBeDeletedBecauseOfAnError;
var
  Consumer: Shared<TRemoveUserConsumerController>;

  Logger: Mock<ILogger>;
  UseCase: IRemoveUseCase;
  Repository: IUserRepository;
  InsertGateway: IInsertGateway;
  DeleteUserGateway: IDeleteUserGateway;
  GetAllUsersGateway: IGetAllUsersGateway;
  GetUsersCountGateway: IGetUsersCountGateway;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  GetAllUsersQuery: Mock<IGetAllUsersQuery>;
  GetUsersCountQuery: Mock<IGetUsersCountQuery>;

  UserId: TGuid;
begin
  UserId := MockUtils.SomeGuid;

  Logger := Mock<ILogger>.Create;

  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  DeleteUserCommand.Setup.Raises<EAdaptersControllersConsumersRemoveUserTests>.When.Execute(UserId.ToString);

  GetAllUsersQuery := Mock<IGetAllUsersQuery>.Create;
  GetUsersCountQuery := Mock<IGetUsersCountQuery>.Create;

  InsertGateway := TInsertGateway.Create(InsertUserCommand);
  DeleteUserGateway := TDeleteUserGateway.Create(DeleteUserCommand);
  GetAllUsersGateway := TGetAllUsersGateway.Create(GetAllUsersQuery);
  GetUsersCountGateway := TGetUsersCountGateway.Create(GetUsersCountQuery);

  Repository := TUserRepository.Create(InsertGateway, DeleteUserGateway, GetAllUsersGateway, GetUsersCountGateway);

  UseCase := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Consumer := TRemoveUserConsumerController.Create(
    Logger,
    UseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Consumer.Value.Run(UserId);
    end);

  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  DeleteUserCommand.Received(Times.Once).Execute(UserId.ToString);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserId.ToString]));
  GetAllUsersQuery.Received(Times.Never).Open(Arg.IsAny<string>, Arg.IsAny<Integer>, Arg.IsAny<Integer>);
  GetUsersCountQuery.Received(Times.Never).Open;
end;

procedure TAdaptersControllersConsumersRemoveUserTests.RunDoesNotRaiseAnyExceptionWhenUserCanBeDeleted;
var
  Consumer: Shared<TRemoveUserConsumerController>;

  Logger: Mock<ILogger>;
  UseCase: IRemoveUseCase;
  Repository: IUserRepository;
  InsertGateway: IInsertGateway;
  DeleteUserGateway: IDeleteUserGateway;
  GetAllUsersGateway: IGetAllUsersGateway;
  GetUsersCountGateway: IGetUsersCountGateway;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  GetAllUsersQuery: Mock<IGetAllUsersQuery>;
  GetUsersCountQuery: Mock<IGetUsersCountQuery>;

  UserId: TGuid;
begin
  UserId := MockUtils.SomeGuid;

  Logger := Mock<ILogger>.Create;

  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  DeleteUserCommand.Setup.Returns<Integer>(1).When.Execute(UserId.ToString);
  GetAllUsersQuery := Mock<IGetAllUsersQuery>.Create;
  GetUsersCountQuery := Mock<IGetUsersCountQuery>.Create;

  InsertGateway := TInsertGateway.Create(InsertUserCommand);
  DeleteUserGateway := TDeleteUserGateway.Create(DeleteUserCommand);
  GetAllUsersGateway := TGetAllUsersGateway.Create(GetAllUsersQuery);
  GetUsersCountGateway := TGetUsersCountGateway.Create(GetUsersCountQuery);

  Repository := TUserRepository.Create(InsertGateway, DeleteUserGateway, GetAllUsersGateway, GetUsersCountGateway);

  UseCase := TRemoveUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Consumer := TRemoveUserConsumerController.Create(
    Logger,
    UseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Consumer.Value.Run(UserId);
    end);

  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  DeleteUserCommand.Received(Times.Once).Execute(UserId.ToString);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsNotIn<string>([UserId.ToString]));
  GetAllUsersQuery.Received(Times.Never).Open(Arg.IsAny<string>, Arg.IsAny<Integer>, Arg.IsAny<Integer>);
  GetUsersCountQuery.Received(Times.Never).Open;
  Logger.Received(Times.Never).Log(Arg.IsAny<string>, Arg.IsAny<Exception>);
end;

initialization
  TDUnitX.RegisterTestFixture(TAdaptersControllersConsumersRemoveUserTests);

end.
