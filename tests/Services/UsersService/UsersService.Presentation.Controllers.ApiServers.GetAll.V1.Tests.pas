unit UsersService.Presentation.Controllers.ApiServers.GetAll.V1.Tests;

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

  FidoApp.Constants,
  FidoApp.Types,

  UsersService.Presentation.Controllers.ApiServers.GetAll.V1,
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
  UsersService.Domain.UseCases.GetAll,
  UsersService.Domain.UseCases.GetAll.Intf,
  UsersService.Domain.Entities.User;

type
  EUSersServiceAdaptersControllersApiServersGetAllV1Tests = class(EFidoException);

  [TestFixture]
  TUsersServiceAdaptersControllersApiServersGetAllV1Tests = class
  public
    [Test]
    procedure ExecuteReturnsUsersWhenAreAvailable;

    [Test]
    procedure ExecuteRaisesEGetAllUseCaseFailureWhenUsersAreMalformed;

    [Test]
    procedure ExecuteRaisesEGetAllUseCaseFailureWhenUsersCannotBeReadFromGateway;

    [Test]
    procedure ExecuteRaisesEApiServer400WhenOrderByIsMalformed;
  end;

implementation

{ TUsersServiceAdaptersControllersApiServersGetAllV1Tests }

procedure TUsersServiceAdaptersControllersApiServersGetAllV1Tests.ExecuteRaisesEApiServer400WhenOrderByIsMalformed;
var
  Resource: Shared<TGetAllV1ApiServerController>;
  UseCase: IGetAllUseCase;
  Repository: IUserRepository;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  GetAllUsersQuery: Mock<IGetAllUsersQuery>;
  GetUsersCountQuery: Mock<IGetUsersCountQuery>;
  InsertGateway: IInsertGateway;
  DeleteUserGateway: IDeleteUserGateway;
  GetAllUsersGateway: IGetAllUsersGateway;
  GetUsersCountGateway: IGetUsersCountGateway;

  Logger: Mock<ILogger>;
  Result: TGetAllV1Result;
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

  UseCase := TGetAllUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Resource := TGetAllV1ApiServerController.Create(

    UseCase);

  Assert.WillRaise(
    procedure
    begin
      Result := Resource.Value.Execute(TGetAllUsersOrderBy(-1), 4, 50);
    end,
    EApiServer400);

  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>);
  GetAllUsersQuery.Received(Times.Never).Open(Arg.IsAny<string>, Arg.IsAny<Integer>, Arg.IsAny<Integer>);
  GetUsersCountQuery.Received(Times.Never).Open;
end;

procedure TUsersServiceAdaptersControllersApiServersGetAllV1Tests.ExecuteRaisesEGetAllUseCaseFailureWhenUsersAreMalformed;
var
  Resource: Shared<TGetAllV1ApiServerController>;
  UseCase: IGetAllUseCase;
  Repository: IUserRepository;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  GetAllUsersQuery: Mock<IGetAllUsersQuery>;
  GetUsersCountQuery: Mock<IGetUsersCountQuery>;
  InsertGateway: IInsertGateway;
  DeleteUserGateway: IDeleteUserGateway;
  GetAllUsersGateway: IGetAllUsersGateway;
  GetUsersCountGateway: IGetUsersCountGateway;

  List: IList<IUserRecord>;
  ReadOnlyList: IReadonlyList<IUserRecord>;

  Logger: Mock<ILogger>;
  Result: TGetAllV1Result;

  Id1: string;
  FirstName1: string;
  LastName1: string;
  Active1: Integer;
begin
  Logger := Mock<ILogger>.Create;

  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  GetAllUsersQuery := Mock<IGetAllUsersQuery>.Create;
  GetUsersCountQuery := Mock<IGetUsersCountQuery>.Create;

  Id1 := MockUtils.SomeString;
  FirstName1 := MockUtils.SomeString;
  LastName1 := MockUtils.SomeString;
  Active1 := 1;

  List := TCollections.CreateList<IUserRecord>(
    [
      JSONUnmarshaller.To<IUserRecord>(
        Format(
          '{"Id": "%s", "FirstName": "%s", "LastName": "%s", "Active": %d}',
          [Id1, FirstName1, LastName1, Active1]))
    ]);

  ReadOnlyList := List.AsReadOnly;

  GetAllUsersQuery.Setup.Returns<IReadonlyList<IUserRecord>>(ReadOnlyList).When.Open('firstname', 50, 150);

  InsertGateway := TInsertGateway.Create(InsertUserCommand);
  DeleteUserGateway := TDeleteUserGateway.Create(DeleteUserCommand);
  GetAllUsersGateway := TGetAllUsersGateway.Create(GetAllUsersQuery);
  GetUsersCountGateway := TGetUsersCountGateway.Create(GetUsersCountQuery);

  Repository := TUserRepository.Create(InsertGateway, DeleteUserGateway, GetAllUsersGateway, GetUsersCountGateway);

  UseCase := TGetAllUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Resource := TGetAllV1ApiServerController.Create(

    UseCase);

  Assert.WillRaise(
    procedure
    begin
      Result := Resource.Value.Execute(FirstNameAsc, 4, 50);
    end,
    EGetAllUseCaseFailure);

  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>);
  GetAllUsersQuery.Received(Times.Once).Open('firstname', 50, 150);
  GetAllUsersQuery.Received(Times.Never).Open(Arg.IsNotIn<string>(['firstname']), Arg.IsNotIn<Integer>([50]), Arg.IsNotIn<Integer>([150]));
  GetUsersCountQuery.Received(Times.Never).Open;
end;

procedure TUsersServiceAdaptersControllersApiServersGetAllV1Tests.ExecuteRaisesEGetAllUseCaseFailureWhenUsersCannotBeReadFromGateway;
var
  Resource: Shared<TGetAllV1ApiServerController>;
  UseCase: IGetAllUseCase;
  Repository: IUserRepository;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  GetAllUsersQuery: Mock<IGetAllUsersQuery>;
  GetUsersCountQuery: Mock<IGetUsersCountQuery>;
  InsertGateway: IInsertGateway;
  DeleteUserGateway: IDeleteUserGateway;
  GetAllUsersGateway: IGetAllUsersGateway;
  GetUsersCountGateway: IGetUsersCountGateway;

  Logger: Mock<ILogger>;
  Result: TGetAllV1Result;
begin
  Logger := Mock<ILogger>.Create;

  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  GetAllUsersQuery := Mock<IGetAllUsersQuery>.Create;
  GetUsersCountQuery := Mock<IGetUsersCountQuery>.Create;

  GetAllUsersQuery.Setup.Raises<EUSersServiceAdaptersControllersApiServersGetAllV1Tests>.When.Open('firstname', 50, 150);

  InsertGateway := TInsertGateway.Create(InsertUserCommand);
  DeleteUserGateway := TDeleteUserGateway.Create(DeleteUserCommand);
  GetAllUsersGateway := TGetAllUsersGateway.Create(GetAllUsersQuery);
  GetUsersCountGateway := TGetUsersCountGateway.Create(GetUsersCountQuery);

  Repository := TUserRepository.Create(InsertGateway, DeleteUserGateway, GetAllUsersGateway, GetUsersCountGateway);

  UseCase := TGetAllUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Resource := TGetAllV1ApiServerController.Create(

    UseCase);

  Assert.WillRaise(
    procedure
    begin
      Result := Resource.Value.Execute(FirstNameAsc, 4, 50);
    end,
    EGetAllUseCaseFailure);

  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>);
  GetAllUsersQuery.Received(Times.Once).Open('firstname', 50, 150);
  GetAllUsersQuery.Received(Times.Never).Open(Arg.IsNotIn<string>(['firstname']), Arg.IsNotIn<Integer>([50]), Arg.IsNotIn<Integer>([150]));
  GetUsersCountQuery.Received(Times.Never).Open;
end;

procedure TUsersServiceAdaptersControllersApiServersGetAllV1Tests.ExecuteReturnsUsersWhenAreAvailable;
var
  Resource: Shared<TGetAllV1ApiServerController>;
  UseCase: IGetAllUseCase;
  Repository: IUserRepository;
  InsertUserCommand: Mock<IInsertUserCommand>;
  DeleteUserCommand: Mock<IDeleteUserCommand>;
  GetAllUsersQuery: Mock<IGetAllUsersQuery>;
  GetUsersCountQuery: Mock<IGetUsersCountQuery>;
  InsertGateway: IInsertGateway;
  DeleteUserGateway: IDeleteUserGateway;
  GetAllUsersGateway: IGetAllUsersGateway;
  GetUsersCountGateway: IGetUsersCountGateway;

  List: IList<IUserRecord>;
  ReadOnlyList: IReadonlyList<IUserRecord>;

  Logger: Mock<ILogger>;
  Result: TGetAllV1Result;

  Id1: TGuid;
  FirstName1: string;
  LastName1: string;
  Active1: Integer;
  Id2: TGuid;
  FirstName2: string;
  LastName2: string;
  Active2: Integer;
begin
  Logger := Mock<ILogger>.Create;

  InsertUserCommand := Mock<IInsertUserCommand>.Create;
  DeleteUserCommand := Mock<IDeleteUserCommand>.Create;
  GetAllUsersQuery := Mock<IGetAllUsersQuery>.Create;

  Id1 := MockUtils.SomeGuid;
  FirstName1 := MockUtils.SomeString;
  LastName1 := MockUtils.SomeString;
  Active1 := 1;

  Id2 := MockUtils.SomeGuid;
  FirstName2 := MockUtils.SomeString;
  LastName2 := MockUtils.SomeString;
  Active2 := 0;

  List := TCollections.CreateList<IUserRecord>(
    [
      JSONUnmarshaller.To<IUserRecord>(
        Format(
          '{"Id": "%s", "FirstName": "%s", "LastName": "%s", "Active": %d}',
          [Id1.ToString.DeQuotedString('"'), FirstName1, LastName1, Active1])),
      JSONUnmarshaller.To<IUserRecord>(
        Format(
          '{"Id": "%s", "FirstName": "%s", "LastName": "%s", "Active": %d}',
          [Id2.ToString.DeQuotedString('"'), FirstName2, LastName2, Active2]))
    ]);

  ReadOnlyList := List.AsReadOnly;

  GetAllUsersQuery.Setup.Returns<IReadonlyList<IUserRecord>>(ReadOnlyList).When.Open('firstname', 50, 150);

  GetUsersCountQuery := Mock<IGetUsersCountQuery>.Create;
  GetUsersCountQuery.Setup.Returns<Integer>(152).When.Open;

  InsertGateway := TInsertGateway.Create(InsertUserCommand);
  DeleteUserGateway := TDeleteUserGateway.Create(DeleteUserCommand);
  GetAllUsersGateway := TGetAllUsersGateway.Create(GetAllUsersQuery);
  GetUsersCountGateway := TGetUsersCountGateway.Create(GetUsersCountQuery);

  Repository := TUserRepository.Create(InsertGateway, DeleteUserGateway, GetAllUsersGateway, GetUsersCountGateway);

  UseCase := TGetAllUseCase.Create(
    function: IUserRepository
    begin
      Result := Repository;
    end);

  Resource := TGetAllV1ApiServerController.Create(

    UseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Result := Resource.Value.Execute(FirstNameAsc, 4, 50);
    end);

  assert.AreEqual(152, Result.Count, 'Result.Count');
  assert.AreEqual(Id1, Result.Users[0].Id, 'Result[0].Id');
  assert.AreEqual(FirstName1, Result.Users[0].FirstName, 'Result[0].FirstName');
  assert.AreEqual(LastName1, Result.Users[0].LastName, 'Result[0].LastName');
  assert.AreEqual(Active1 = 1, Result.Users[0].Active, 'Result[0].Active');
  assert.AreEqual(Id2, Result.Users[1].Id, 'Result[1].Id');
  assert.AreEqual(FirstName2, Result.Users[1].FirstName, 'Result[1].FirstName');
  assert.AreEqual(LastName2, Result.Users[1].LastName, 'Result[1].LastName');
  assert.AreEqual(Active2 = 1, Result.Users[1].Active, 'Result[1].Active');

  InsertUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>, Arg.IsAny<string>, Arg.IsAny<string>);
  DeleteUserCommand.Received(Times.Never).Execute(Arg.IsAny<string>);
  GetAllUsersQuery.Received(Times.Once).Open('firstname', 50, 150);
  GetAllUsersQuery.Received(Times.Never).Open(Arg.IsNotIn<string>(['firstname']), Arg.IsNotIn<Integer>([50]), Arg.IsNotIn<Integer>([150]));
  GetUsersCountQuery.Received(Times.Once).Open;
end;

initialization
  TDUnitX.RegisterTestFixture(TUsersServiceAdaptersControllersApiServersGetAllV1Tests);

end.
