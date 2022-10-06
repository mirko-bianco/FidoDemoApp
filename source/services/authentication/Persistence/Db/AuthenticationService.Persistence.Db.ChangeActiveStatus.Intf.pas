unit AuthenticationService.Persistence.Db.ChangeActiveStatus.Intf;

interface

uses
  Fido.VirtualStatement.Intf,
  Fido.VirtualStatement.Attributes;

type

  [Statement(stCommand, 'SQL_AUTHENTICATION_Update')]
  IUpdateActiveStatusCommand = interface(IVirtualStatement)
    ['{73914610-252F-4B27-8BB1-62DC498672AD}']

    function Execute(const Id: string; const Active: Integer): Integer;
  end;

implementation

end.
