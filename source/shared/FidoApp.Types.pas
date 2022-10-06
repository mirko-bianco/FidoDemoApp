unit FidoApp.Types;

interface

uses
  Spring.Collections;

type
  Permission = (
      CanChangeUserState,
      CanSetUserRole,
      CanGetAllUSers
    );

  {$M+}
  IUserRoleAndPermissions = interface(IInvokable)
    ['{B4E61D67-97A9-4E2F-B1DE-2A465E640106}']

    function Role: string;
    function Permissions: IReadonlyList<Permission>;
  end;

  ITokens = interface
    ['{81B78CED-745D-4F1E-9B75-6C130BE60D9B}']

    function AccessToken: string;
    function RefreshToken: string;
  end;

  IUser = interface(IInvokable)
    ['{FD7749AC-468D-474F-B898-E9C497E723D3}']

    function Id: TGuid;
    function FirstName: string;
    function LastName: string;
    function Active: Boolean;
  end;

  IGetAllUsersV1Result = interface(IInvokable)
    ['{4F6E3CB3-7662-4088-99E2-A64EC65F3232}']

    function Count: Integer;
    function Users: IReadonlyList<IUser>;
  end;
  {$M-}

  TGetAllUsersOrderBy = (FirstNameAsc, FirstNameDesc, LastNameAsc, LastNameDesc);

implementation

end.
