unit AuthorizationService.Domain.ValueObjects.RolesAndPermissions;

interface

uses
  System.Generics.Defaults,

  Spring,
  Spring.Collections,

  FidoApp.Types,
  FidoApp.Constants;

type
  IPermissions = IReadonlyList<Permission>;

  TRolesAndPermissions = record
  private class var
    FAvailablePermissions: IPermissions;
    FAvailableRoles: IReadonlyDictionary<string, IPermissions>;
  public
    class constructor Create;

    class function AvailableRoles: IReadonlyDictionary<string, IPermissions>; static;
  end;

implementation

{ TRolesAndPermissions }

class function TRolesAndPermissions.AvailableRoles: IReadonlyDictionary<string, IPermissions>;
begin
  Result := FAvailableRoles;
end;

class constructor TRolesAndPermissions.Create;
var
  User: IList<Permission>;
  Admin: IList<Permission>;

  AvailablePermissions: IList<Permission>;
  AvailableRoles: IDictionary<string, IPermissions>;
begin
  AvailablePermissions := TCollections.CreateList<Permission>();

  AvailablePermissions.Add(Permission.CanChangeUserState);
  AvailablePermissions.Add(Permission.CanSetUserRole);
  AvailablePermissions.Add(Permission.CanGetAllUSers);

  FAvailablePermissions := AvailablePermissions.AsReadOnly;

  AvailableRoles := TCollections.CreateDictionary<string, IPermissions>(TStringComparer.Ordinal);

  User := TCollections.CreateList<Permission>;

  AvailableRoles[Constants.ROLE_USER] := User.AsReadonly;

  Admin := TCollections.CreateList<Permission>();
  Admin.AddRange(FAvailablePermissions);

  AvailableRoles[Constants.ROLE_ADMIN] := Admin.AsReadonly;

  FAvailableRoles := AvailableRoles.AsReadOnly;
end;

end.
