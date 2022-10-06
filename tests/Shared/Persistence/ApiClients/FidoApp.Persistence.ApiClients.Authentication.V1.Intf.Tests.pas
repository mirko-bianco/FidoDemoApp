unit FidoApp.Persistence.ApiClients.Authentication.V1.Intf.Tests;

interface

uses
  DUnitX.TestFramework,

  Spring.Mocking,

  Fido.Testing.Mock.Utils,

  FidoApp.Persistence.ApiClients.Authentication.V1.Intf;

type
  [TestFixture]
  TDTOTests = class
  public
    [Test]
    procedure LoginParams;

    [Test]
    procedure SignupParams;
  end;

implementation

{ TDTOTests }

procedure TDTOTests.LoginParams;
var
  LoginParams: TLoginParams;
  Username: string;
  Password: string;
begin
  Username := MockUtils.SomeString;
  Password := MockUtils.SomeString;
  LoginParams := TLoginParams.Create(Username, Password);

  Assert.AreEqual(Username, LoginParams.Username, 'LoginParams.Username');
  Assert.AreEqual(Password, LoginParams.Password, 'LoginParams.Password');
end;

procedure TDTOTests.SignupParams;
var
  SignupParams: TSignupParams;
  Username: string;
  Password: string;
  FirstName: string;
  LastName: string;
begin
  Username := MockUtils.SomeString;
  Password := MockUtils.SomeString;
  FirstName := MockUtils.SomeString;
  LastName := MockUtils.SomeString;
  SignupParams := TSignupParams.Create(Username, Password, FirstName, LastName);

  Assert.AreEqual(Username, SignupParams.Username, 'SignupParams.Username');
  Assert.AreEqual(Password, SignupParams.Password, 'SignupParams.Password');
  Assert.AreEqual(FirstName, SignupParams.FirstName, 'SignupParams.FirstName');
  Assert.AreEqual(LastName, SignupParams.LastName, 'SignupParams.LastName');
end;

initialization
 TDUnitX.RegisterTestFixture(TDTOTests);

end.
