unit UsersService.Persistence.Db.Types;

interface

type
  IUserRecord = interface(IInvokable)
    ['{74A812BD-9807-402C-A63C-88681067D9A9}']

    function Id: string;
    function FirstName: string;
    function LastName: string;
    function Active: Integer;
  end;

implementation

end.
