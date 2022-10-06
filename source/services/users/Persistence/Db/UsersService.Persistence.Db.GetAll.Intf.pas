unit UsersService.Persistence.Db.GetAll.Intf;

interface

uses
  Spring.Collections,

  Fido.VirtualQuery.Intf,
  Fido.Virtual.Attributes,
  Fido.VirtualQuery.Attributes,

  UsersService.Persistence.Db.Types;

type
  [SQLResource('SQL_Users_GetAll')]
  IGetAllUsersQuery = interface(IVirtualQuery)
    ['{F051523A-9E2A-42C2-85E5-1A1386BBA8E5}']

    function Open(const [SqlInject('ORDERBY')] OrderBy: string; const [PagingLimit] Limit: Integer; const [PagingOffset] Offset: Integer): IReadOnlyList<IUserRecord>;
  end;

implementation

end.
