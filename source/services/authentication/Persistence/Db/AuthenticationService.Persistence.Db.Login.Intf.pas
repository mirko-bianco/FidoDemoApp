unit AuthenticationService.Persistence.Db.Login.Intf;

interface

uses
  Spring.Collections,

  Fido.VirtualQuery.Intf,
  Fido.VirtualQuery.Attributes;

type

  ILoginDbUserRecord = interface(IInvokable)
    ['{8B681FE2-3C64-4D58-9DF6-0E9561B17E03}']

    function Id: string;
    function Username: string;
	  function HashedPassword: string;
  end;

  [SQLResource('SQL_AUTHENTICATION_Get')]
  IGetUserByUsernameAndHashedPasswordQuery = interface(IVirtualQuery)
    ['{0A3B473B-C3A1-4473-A553-8F094927182F}']

    function Open(const Username: string; const HashedPassword: string): IReadonlyList<ILoginDbUserRecord>;
  end;

implementation

end.
