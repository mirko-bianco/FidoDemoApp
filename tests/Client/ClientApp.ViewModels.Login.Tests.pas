unit ClientApp.ViewModels.Login.Tests;

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
  FidoApp.Domain.ClientTokensCache.Intf,
  FidoApp.Persistence.ApiClients.Authentication.V1.Intf,
  FidoApp.Persistence.Gateways.Authentication.Intf,
  FidoApp.Persistence.Gateways.Authentication,

  ClientApp.Types,
  ClientApp.Messages,
  ClientApp.Models.Domain.Entities.LoginUser,
  ClientApp.Models.Domain.Entities.SignupUser,
  ClientApp.Models.Domain.Usecases.Login,
  ClientApp.Models.Domain.Usecases.Login.Intf,
  ClientApp.Models.Domain.Usecases.Signup,
  ClientApp.Models.Domain.Usecases.Signup.Intf,
  ClientApp.Models.Domain.Repositories.Authentication.Intf,
  ClientApp.Models.Persistence.Repositories.Authentication,
  ClientApp.ViewModels.Login.Intf,
  ClientApp.ViewModels.Login;

type
  ELoginViewModelTests = class(EFidoException);

  [TestFixture]
  TLoginViewModelTests = class
  public
    [Test]
    procedure LoginTriggersViewBusyAndTokenChangedWhenLoginSucceds;

    [Test]
    procedure LoginTriggersViewBusyAndFailedWhenLoginFails;

    [Test]
    procedure SignupTriggersViewBusyAndTokenChangedWhenSignupSucceds;

    [Test]
    procedure SignupTriggersViewBusyAndFailedWhenSignupFails;

    [Test]
    procedure SignupTriggersViewBusyAndFailedWhenValidationFails;

    [Test]
    procedure UsernameAndSetUsernameWorkDoesNotRaiseAnyException;

    [Test]
    procedure PasswordAndSetPasswordWorkDoesNotRaiseAnyException;

    [Test]
    procedure RepeatedPasswordAndSetRepeatedPasswordWorkDoesNotRaiseAnyException;

    [Test]
    procedure FirstNameAndSetFirstNameWorkDoesNotRaiseAnyException;

    [Test]
    procedure LastNameAndSetLastNameWorkDoesNotRaiseAnyException;

    [Test]
    procedure CloseTriggersMessageAndDoesNotRaiseAnyException;

    [Test]
    procedure RunDoesNotRaiseAnyException;
  end;

implementation

{ TLoginViewModelTests }

procedure TLoginViewModelTests.LoginTriggersViewBusyAndTokenChangedWhenLoginSucceds;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
  Token: string;
  Username: string;
  Password: string;
begin
  Token := MockUtils.SomeString;
  Username := MockUtils.SomeString;
  Password := MockUtils.SomeString;

  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', TOKEN_CHANGED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_FAILED_MESSAGE, ['']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;
  Api.Setup.Executes.When.Login(Arg.IsAny<TLoginParams>);

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.SetUsername(Username);
      LoginViewModel.SetPassword(Password);
      LoginViewModel.Run;
    end);

  Api.Received(Times.Once).Login(Arg.IsAny<TLoginParams>);
  Api.Received(Times.Never).Signup(Arg.IsAny<TSignupParams>);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', TOKEN_CHANGED_MESSAGE, []);
  Publisher.Received(Times.Never).Trigger('LoginViewModel', LOGIN_FAILED_MESSAGE, ['']);
end;

procedure TLoginViewModelTests.PasswordAndSetPasswordWorkDoesNotRaiseAnyException;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
  Password: string;
  ExpectedPassword: string;
begin
  Password := MockUtils.SomeString;

  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.SetPassword(Password);
      ExpectedPassword := LoginViewModel.Password;
    end);

  Assert.AreEqual(ExpectedPassword, Password);
end;

procedure TLoginViewModelTests.RepeatedPasswordAndSetRepeatedPasswordWorkDoesNotRaiseAnyException;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
  RepeatedPassword: string;
  ExpectedRepeatedPassword: string;
begin
  RepeatedPassword := MockUtils.SomeString;

  Publisher := Mock<IEventsDrivenPublisher>.Create;
  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.SetRepeatedPassword(RepeatedPassword);
      ExpectedRepeatedPassword := LoginViewModel.RepeatedPassword;
    end);

  Assert.AreEqual(ExpectedRepeatedPassword, RepeatedPassword);
end;

procedure TLoginViewModelTests.RunDoesNotRaiseAnyException;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
  Token: string;
  Username: string;
  Password: string;
  RepeatPassword: string;
  FirstName: string;
  LastName: string;
begin
  Token := MockUtils.SomeString;
  Username := MockUtils.SomeString;
  Password := MockUtils.SomeString;
  RepeatPassword := Password;
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Login)]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Signup)]);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;
  Api.Setup.Executes.When.Login(Arg.IsAny<TLoginParams>);

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.SwitchAction;
      LoginViewModel.SetUsername(Username);
      LoginViewModel.SetPassword(Password);
      LoginViewModel.SetRepeatedPassword(RepeatPassword);
      LoginViewModel.SetFirstName(FirstName);
      LoginViewModel.SetLastName(LastName);
      LoginViewModel.Run;

      Sleep(100);
    end);

  Api.Received(Times.Never).Login(Arg.IsAny<TLoginParams>);
  Api.Received(Times.Once).Signup(Arg.IsAny<TSignupParams>);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Login)]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Signup)]);
end;

procedure TLoginViewModelTests.SignupTriggersViewBusyAndTokenChangedWhenSignupSucceds;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
  Token: string;
  Username: string;
  Password: string;
  RepeatPassword: string;
  FirstName: string;
  LastName: string;
begin
  Token := MockUtils.SomeString;
  Username := MockUtils.SomeString;
  Password := MockUtils.SomeString;
  RepeatPassword := Password;
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Login)]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Signup)]);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;
  Api.Setup.Returns<TGuid>(MockUtils.SomeGuid).When.Signup(Arg.IsAny<TSignupParams>);

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.SwitchAction;
      LoginViewModel.SetUsername(Username);
      LoginViewModel.SetPassword(Password);
      LoginViewModel.SetRepeatedPassword(RepeatPassword);
      LoginViewModel.SetFirstName(FirstName);
      LoginViewModel.SetLastName(LastName);
      LoginViewModel.Run;
    end);

  Api.Received(Times.Never).Login(Arg.IsAny<TLoginParams>);
  Api.Received(Times.Once).Signup(Arg.IsAny<TSignupParams>);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Login)]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Signup)]);
end;

procedure TLoginViewModelTests.UsernameAndSetUsernameWorkDoesNotRaiseAnyException;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
  Username: string;
  ExpectedUsername: string;
begin
  Username := MockUtils.SomeString;

  Publisher := Mock<IEventsDrivenPublisher>.Create;
  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.SetUsername(Username);
      ExpectedUsername := LoginViewModel.Username;
    end);

  Assert.AreEqual(ExpectedUsername, Username);
end;

procedure TLoginViewModelTests.CloseTriggersMessageAndDoesNotRaiseAnyException;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
begin
  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_CLOSED_MESSAGE, []);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.Close;
    end);

  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_CLOSED_MESSAGE, []);
end;

procedure TLoginViewModelTests.FirstNameAndSetFirstNameWorkDoesNotRaiseAnyException;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
  FirstName: string;
  ExpectedFirstName: string;
begin
  FirstName := MockUtils.SomeString;

  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.SetFirstName(FirstName);
      ExpectedFirstName := LoginViewModel.FirstName;
    end);

  Assert.AreEqual(ExpectedFirstName, FirstName);
end;

procedure TLoginViewModelTests.LastNameAndSetLastNameWorkDoesNotRaiseAnyException;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
  LastName: string;
  ExpectedLastName: string;
begin
  LastName := MockUtils.SomeString;

  Publisher := Mock<IEventsDrivenPublisher>.Create;
  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.SetLastName(LastName);
      ExpectedLastName := LoginViewModel.LastName;
    end);

  Assert.AreEqual(ExpectedLastName, LastName);
end;

procedure TLoginViewModelTests.LoginTriggersViewBusyAndFailedWhenLoginFails;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
  Token: string;
  Username: string;
  Password: string;
begin
  Token := MockUtils.SomeString;
  Username := MockUtils.SomeString;
  Password := MockUtils.SomeString;

  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', TOKEN_CHANGED_MESSAGE, []);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_FAILED_MESSAGE, ['0: ']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;
  Api.Setup.Raises<EFidoClientApiException>.When.Login(Arg.IsAny<TLoginParams>);

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.SetUsername(Username);
      LoginViewModel.SetPassword(Password);
      LoginViewModel.Run;
    end);

  Api.Received(Times.Once).Login(Arg.IsAny<TLoginParams>);
  Api.Received(Times.Never).Signup(Arg.IsAny<TSignupParams>);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Never).Trigger('LoginViewModel', TOKEN_CHANGED_MESSAGE, []);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', LOGIN_FAILED_MESSAGE, ['0: ']);
end;

procedure TLoginViewModelTests.SignupTriggersViewBusyAndFailedWhenSignupFails;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
  Token: string;
  Username: string;
  Password: string;
  RepeatPassword: string;
  FirstName: string;
  LastName: string;
begin
  Token := MockUtils.SomeString;
  Username := MockUtils.SomeString;
  Password := MockUtils.SomeString;
  RepeatPassword := Password;
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Login)]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Signup)]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_FAILED_MESSAGE, ['-1: Could not signup at this time']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;
  Api.Setup.Raises<ELoginViewModelTests>.When.Signup(Arg.IsAny<TSignupParams>);

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);
  LoginViewModel.SwitchAction;

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.SetUsername(Username);
      LoginViewModel.SetPassword(Password);
      LoginViewModel.SetRepeatedPassword(RepeatPassword);
      LoginViewModel.SetFirstName(FirstName);
      LoginViewModel.SetLastName(LastName);
      LoginViewModel.Run;
    end);

  Api.Received(Times.Never).Login(Arg.IsAny<TLoginParams>);
  Api.Received(Times.Once).Signup(Arg.IsAny<TSignupParams>);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Never).Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Login)]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Signup)]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', LOGIN_FAILED_MESSAGE, ['-1: Could not signup at this time']);
end;

procedure TLoginViewModelTests.SignupTriggersViewBusyAndFailedWhenValidationFails;
var
  Publisher: Mock<IEventsDrivenPublisher>;
  LoginUseCase: ILoginUseCase;
  SignupUseCase: ISignupUseCase;
  LoginViewModel: ILoginViewModel;
  Repository: IAuthenticationRepository;
  Gateway: IAuthenticationV1ApiClientGateway;
  Api: Mock<IAuthenticationV1ApiClient>;
  Logger: Mock<ILogger>;
  Token: string;
  Username: string;
  Password: string;
  RepeatPassword: string;
  FirstName: string;
  LastName: string;
begin
  Token := MockUtils.SomeString;
  Username := MockUtils.SomeString;
  Password := MockUtils.SomeString;
  RepeatPassword := MockUtils.SomeString;
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;

  Publisher := Mock<IEventsDrivenPublisher>.Create;

  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Login)]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Signup)]);
  Publisher.Setup.Returns<Context<Boolean>>(True).When.Trigger('LoginViewModel', LOGIN_FAILED_MESSAGE, ['Password and repeated password are not the same.']);

  Logger := Mock<ILogger>.Create;

  Api := Mock<IAuthenticationV1ApiClient>.Create;

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);

  LoginUseCase := TLoginUseCase.Create(Logger, Repository);

  SignupUseCase := TSignupUseCase.Create(Logger, Repository);

  LoginViewModel := TLoginViewModel.Create(Publisher, LoginUseCase, SignupUseCase);
  LoginViewModel.SwitchAction;

  Assert.WillNotRaiseAny(
    procedure
    begin
      LoginViewModel.SetUsername(Username);
      LoginViewModel.SetPassword(Password);
      LoginViewModel.SetRepeatedPassword(RepeatPassword);
      LoginViewModel.SetFirstName(FirstName);
      LoginViewModel.SetLastName(LastName);
      LoginViewModel.Run;
    end);

  Api.Received(Times.Never).Login(Arg.IsAny<TLoginParams>);
  Api.Received(Times.Never).Signup(Arg.IsAny<TSignupParams>);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [True]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', VIEW_BUSY_MESSAGE, [False]);
  Publisher.Received(Times.Never).Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Login)]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', LOGIN_VIEW_ACTION_CHANGED, [TValue.From<TLoginViewAction>(TLoginViewAction.Signup)]);
  Publisher.Received(Times.Once).Trigger('LoginViewModel', LOGIN_FAILED_MESSAGE, ['Password and repeated password are not the same.']);
end;

initialization
  TDUnitX.RegisterTestFixture(TLoginViewModelTests);

end.
