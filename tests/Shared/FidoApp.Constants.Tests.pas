unit FidoApp.Constants.Tests;

interface

uses
  DUnitX.TestFramework,

  FidoApp.Types,
  FidoApp.Utils,
  FidoApp.Constants;

type
  [TestFixture]
  TFidoAppConstantsTests = class
  public
    [Test]
    procedure GetAuthenticatedReturnsTrueWhenUserIsAuthenticated;
  end;

implementation

{ TFidoAppConstantsTests }

procedure TFidoAppConstantsTests.GetAuthenticatedReturnsTrueWhenUserIsAuthenticated;
var
  Perm: Permission;
begin
  Assert.IsTrue(Utils.Permissions.TryGetFromLabel(Constants.PERMISSION_CAN_CHANGE_USER_STATE, Perm));
  Assert.AreEqual(Permission.CanChangeUserState, Perm);
  Assert.IsTrue(Utils.Permissions.TryGetFromLabel(Constants.PERMISSION_CAN_SET_USER_ROLE, Perm));
  Assert.AreEqual(Permission.CanSetUserRole, Perm);
  Assert.IsTrue(Utils.Permissions.TryGetFromLabel(Constants.PERMISSION_CAN_GET_ALL_USERS, Perm));
  Assert.AreEqual(Permission.CanGetAllUSers, Perm);
end;

initialization
  TDUnitX.RegisterTestFixture(TFidoAppConstantsTests);

end.
