unit UsersService.Persistence.Gateways.GetCount;

interface

uses
  Fido.Utilities,
  Fido.Functional,

  UsersService.Persistence.Gateways.GetCount.Intf,
  UsersService.Persistence.Db.GetCount.Intf;

type
  TGetUsersCountGateway = class(TInterfacedObject, IGetUsersCountGateway)
  private
    FQuery: IGetUsersCountQuery;
    function DoGet: Integer;

  public
    constructor Create(const Query: IGetUsersCountQuery);

    function Open: Context<Integer>;
  end;

implementation

{ TGetUsersCountGateway }

constructor TGetUsersCountGateway.Create(const Query: IGetUsersCountQuery);
begin
  inherited Create;

  FQuery := Utilities.CheckNotNullAndSet(Query, 'Query');
end;

function TGetUsersCountGateway.DoGet: Integer;
begin
  Result := FQuery.Open;
end;

function TGetUsersCountGateway.Open: Context<Integer>;
begin
  Result := DoGet;
end;

end.
