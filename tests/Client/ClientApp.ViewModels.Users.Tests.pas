unit ClientApp.ViewModels.Users.Tests;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Threading,

  DUnitX.TestFramework,

  Spring,
  Spring.Times,
  Spring.Collections,
  Spring.Mocking,
  Spring.Logging,

  Fido.Functional,
  Fido.Exceptions,
  Fido.Types,
  Fido.DesignPatterns.Observer.Intf,
  Fido.DesignPatterns.Observer.Notification.Intf,
  Fido.Testing.Mock.Utils,
  Fido.Api.Client.Exception,
  Fido.JSON.Marshalling,
  Fido.EventsDriven.Publisher.Intf,

  FidoApp.Types,
  FidoApp.Messages,
  FidoApp.Persistence.ApiClients.Users.V1.Intf,
  FidoApp.Persistence.Gateways.Users.Intf,
  FidoApp.Persistence.Gateways.Users,

  ClientApp.Types,
  ClientApp.Messages,
  ClientApp.Models.Domain.Repositories.Users.Intf,
  ClientApp.Models.Domain.UseCases.GetAllUsers.Intf,
  ClientApp.Models.Domain.UseCases.GetAllUsers,
  ClientApp.Models.Persistence.Repositories.Users,
  ClientApp.ViewModels.Users.Intf,
  ClientApp.ViewModels.Users;

type
  ELoginViewModelTests = class(EFidoException);

  [TestFixture]
  TLoginViewModelTests = class
  private
    function NewMockedUser: IUser;
  public
    [Test]
    procedure RunAndCloseWorkCorrectlyIfThereAreNoErrors;

    [Test]
    [TestCase('Last', '5')]
    [TestCase('Middle', '3')]
    procedure ChangePageNumberDoesNotRaiseAnyExceptionWhenNewPageIsValid(const NewPage: Integer);

    [Test]
    [TestCase('Zero', '0')]
    [TestCase('Less than zero', '-2')]
    [TestCase('More than page count', '100')]
    procedure ChangePageNumberDoesRaisesEUsersViewModelWhenNewPageIsNotValid(const NewPage: Integer);

    [Test]
    procedure RunNotifiesAGetAllUsersFailedMessageWhenGatewayRaisesAClientApiException;

    [Test]
    procedure ChangingTheOrderByToADifferentOneTriggersARun;

    [Test]
    procedure ChangingTheOrderByToSameOneDoesNotTriggersARun;

    [Test]
    procedure CanPriorReturnsFalseWhenThePageIsTheFirst;

    [Test]
    procedure CanPriorReturnsTrueWhenThePageIsNotTheFirst;

    [Test]
    procedure CanNextReturnsFalseWhenThePageIsTheLast;

    [Test]
    procedure CanNextReturnsTrueWhenThePageIsNotTheLast;

    [Test]
    procedure NextRaisesEUsersViewModelWhenThePageIsTheLast;

    [Test]
    procedure PriorRaisesEUsersViewModelWhenThePageIsTheFirst;

    [Test]
    procedure PriorRaisesWorksWhenThePageIsNotTheFirst;
  end;

implementation

{ TLoginViewModelTests }

procedure TLoginViewModelTests.CanNextReturnsFalseWhenThePageIsTheLast;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Api: Mock<IUsersV1ApiClient>;
  Gateway: IUsersV1ApiClientGateway;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(Arg.IsIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsIn<Integer>([1, 3]), Arg.IsIn<Integer>([20]));

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      UsersViewModel.Run.Value;
      UsersViewModel.ChangePageNumber(UsersViewModel.PagesCount).Value;
      Assert.IsFalse(UsersViewModel.CanNext);
      UsersViewModel.Close;
    end);

  Assert.AreEqual(3, UsersViewModel.PagesCount);
  Assert.AreEqual(3, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 3, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1, 3]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

procedure TLoginViewModelTests.CanNextReturnsTrueWhenThePageIsNotTheLast;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      UsersViewModel.Run.Value;
      Assert.IsTrue(UsersViewModel.CanNext);
      UsersViewModel.Close;
    end);

  Assert.AreEqual(3, UsersViewModel.PagesCount);
  Assert.AreEqual(1, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

procedure TLoginViewModelTests.CanPriorReturnsFalseWhenThePageIsTheFirst;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      UsersViewModel.Run.Value;
      Assert.IsFalse(UsersViewModel.CanPrior);
      UsersViewModel.Close;
    end);

  Assert.AreEqual(3, UsersViewModel.PagesCount);
  Assert.AreEqual(1, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

procedure TLoginViewModelTests.CanPriorReturnsTrueWhenThePageIsNotTheFirst;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(Arg.IsIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsIn<Integer>([1, 2]), Arg.IsIn<Integer>([20]));

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      UsersViewModel.Run.Value;
      UsersViewModel.Next.Value;
      Assert.IsTrue(UsersViewModel.CanPrior);
      UsersViewModel.Close;
    end);

  Assert.AreEqual(3, UsersViewModel.PagesCount);
  Assert.AreEqual(2, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 2, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1, 2]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

procedure TLoginViewModelTests.ChangePageNumberDoesNotRaiseAnyExceptionWhenNewPageIsValid(const NewPage: Integer);
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 100, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(Arg.IsIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsIn<Integer>([1, 3, 5]), Arg.IsIn<Integer>([20]));

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      UsersViewModel.Run.Value;
      UsersViewModel.ChangePageNumber(NewPage).Value;
      UsersViewModel.Close;
    end);

  Assert.AreEqual(5, UsersViewModel.PagesCount);
  Assert.AreEqual(NewPage, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, NewPage, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1, NewPage]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

procedure TLoginViewModelTests.ChangePageNumberDoesRaisesEUsersViewModelWhenNewPageIsNotValid(const NewPage: Integer);
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 100, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(Arg.IsIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsIn<Integer>([1]), Arg.IsIn<Integer>([20]));

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillRaise(
    procedure
    begin
      UsersViewModel.Run.Value;
      UsersViewModel.ChangePageNumber(NewPage).Value;
      UsersViewModel.Close;
    end,
    EUsersViewModel);

  Assert.AreEqual(5, UsersViewModel.PagesCount);
  Assert.AreEqual(1, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Exactly(1)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Exactly(1)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Exactly(1)).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

procedure TLoginViewModelTests.ChangingTheOrderByToADifferentOneTriggersARun;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(TGetAllUsersOrderBy.FirstNameDesc, 1, 20);

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      UsersViewModel.Run.Value;
      UsersViewModel.ChangeOrderBy(TGetAllUsersOrderBy.FirstNameDesc).Value;
      UsersViewModel.Close;
    end);

  Assert.AreEqual(3, UsersViewModel.PagesCount);
  Assert.AreEqual(1, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameDesc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameDesc, 1, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc, TGetAllUsersOrderBy.FirstNameDesc]), Arg.IsNotIn<Integer>([1]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

procedure TLoginViewModelTests.ChangingTheOrderByToSameOneDoesNotTriggersARun;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(TGetAllUsersOrderBy.FirstNameDesc, 1, 20);

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      UsersViewModel.Run.Value;
      UsersViewModel.ChangeOrderBy(TGetAllUsersOrderBy.FirstNameAsc).Value;
      UsersViewModel.Close;
    end);

  Assert.AreEqual(3, UsersViewModel.PagesCount);
  Assert.AreEqual(1, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Exactly(1)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Exactly(1)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Exactly(1)).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

function TLoginViewModelTests.NewMockedUser: IUser;
begin
  Result := JSONUnMarshaller.To<IUser>(
    Format('{"Id": %s, "FirstName": %s, "LastName": %s, "Active": %s}',
    [
      JSONMarshaller.From<TGuid>(MockUtils.SomeGuid),
      JSONMarshaller.From<string>(MockUtils.SomeString),
      JSONMarshaller.From<string>(MockUtils.SomeString),
      JSONMarshaller.From<Boolean>(MockUtils.SomeBoolean)
    ]));
end;

procedure TLoginViewModelTests.NextRaisesEUsersViewModelWhenThePageIsTheLast;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(Arg.IsIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsIn<Integer>([1, 3]), Arg.IsIn<Integer>([20]));

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillRaise(
    procedure
    begin
      UsersViewModel.Run.Value;
      UsersViewModel.ChangePageNumber(UsersViewModel.PagesCount).Value;
      UsersViewModel.Next.Value;
    end,
    EUsersViewModel);

  Assert.AreEqual(3, UsersViewModel.PagesCount);
  Assert.AreEqual(3, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 3, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1, 3]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Exactly(2)).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

procedure TLoginViewModelTests.PriorRaisesEUsersViewModelWhenThePageIsTheFirst;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillRaise(
    procedure
    begin
      UsersViewModel.Run.Value;
      UsersViewModel.Prior.Value;
    end,
    EUsersViewModel);

  Assert.AreEqual(3, UsersViewModel.PagesCount);
  Assert.AreEqual(1, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

procedure TLoginViewModelTests.PriorRaisesWorksWhenThePageIsNotTheFirst;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(Arg.IsIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsIn<Integer>([1, 2]), Arg.IsIn<Integer>([20]));

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      UsersViewModel.Run.Value;
      UsersViewModel.Next.Value;
      UsersViewModel.Prior.Value;
    end);

  Assert.AreEqual(3, UsersViewModel.PagesCount);
  Assert.AreEqual(1, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Exactly(2)).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 2, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1, 2]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Exactly(3)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Exactly(3)).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Exactly(3)).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

procedure TLoginViewModelTests.RunAndCloseWorkCorrectlyIfThereAreNoErrors;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
  Users: IList<IUser>;
  Index: Integer;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;

  Users := TCollections.CreateList<IUser>;
  for Index := 1 to 20 do
    Users.Add(NewMockedUser);

  Api.Setup.Returns<IGetAllUsersV1Result>(JSONUnMarshaller.To<IGetAllUsersV1Result>(Format('{"Count": 55, "Users": %s}', [JSONMarshaller.From<IReadonlyList<IUser>>(Users.AsReadOnlyList)]))).
    When.GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      UsersViewModel.Run.Value;
      UsersViewModel.Close;
    end);

  sleep(10);

  Assert.AreEqual(3, UsersViewModel.PagesCount);
  Assert.AreEqual(1, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(20, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, []);
end;

procedure TLoginViewModelTests.RunNotifiesAGetAllUsersFailedMessageWhenGatewayRaisesAClientApiException;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  GetAllUsersUseCase: IGetAllUsersUseCase;
  UsersViewModel: IUsersViewModel;
  Repository: IUsersRepository;
  Gateway: IUsersV1ApiClientGateway;
  Api: Mock<IUsersV1ApiClient>;
  Logger: Mock<ILogger>;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['0: ']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IUsersV1ApiClient>.Create;
  Api.Setup.Raises<EFidoClientApiException>.When.GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);

  Gateway := TUsersV1ApiClientGateway.Create(Api);

  Repository := TUsersRepository.Create(Gateway);

  GetAllUsersUseCase := TGetAllUsersUseCase.Create(Logger, Repository);

  UsersViewModel := TUsersViewModel.Create(Publisher, GetAllUsersUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      UsersViewModel.Run.Value;
      UsersViewModel.Close;
    end);

  Assert.AreEqual(0, UsersViewModel.PagesCount);
  Assert.AreEqual(1, UsersViewModel.PageNumber);
  Assert.AreEqual(FirstNameAsc, UsersViewModel.OrderBy);
  Assert.AreEqual(0, UsersViewModel.Users.Count);

  Api.Received(Times.Once).GetAll(TGetAllUsersOrderBy.FirstNameAsc, 1, 20);
  Api.Received(Times.Never).GetAll(Arg.IsNotIn<TGetAllUsersOrderBy>([TGetAllUsersOrderBy.FirstNameAsc]), Arg.IsNotIn<Integer>([1]), Arg.IsNotIn<Integer>([20]));
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Never).Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []);
  Publisher.Received(Times.Once).Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, ['0: ']);
end;

initialization
  TDUnitX.RegisterTestFixture(TLoginViewModelTests);

end.
