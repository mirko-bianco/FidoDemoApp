unit UsersService.Persistence.Gateways.GetAll;

interface

uses
  System.SysUtils,
  Generics.Collections,

  Spring,
  Spring.Collections,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Mappers,

  UsersService.Domain.Entities.User,
  UsersService.Persistence.Db.Types,
  UsersService.Persistence.Db.GetAll.Intf,
  UsersService.Persistence.Gateways.GetAll.Intf;

type
  TGetAllUsersGateway = class(TInterfacedObject, IGetAllUsersGateway)
  private type
    TGetAllMappedParams = record
    private
      FOrderBy: string;
      FLimit: Integer;
      FOffset: Integer;
    public
      constructor Create(const OrderBy: string; const Limit: Integer; const Offset: Integer);

      property OrderBy: string read FOrderBy;
      property Limit: Integer read FLimit;
      property Offset: Integer read FOffset;
    end;
  private var
    FQuery: IGetAllUsersQuery;

    function Map(const List: IReadOnlyList<IUserRecord>): IReadOnlyList<TUser>;
    function GetMappedUser(const User: IUserRecord): TUser;
    function DoGetAll(const Params: TGetAllMappedParams): IReadOnlyList<IUserRecord>;
  public
    constructor Create(const Query: IGetAllUsersQuery);

    function Open(const OrderBy: string; const Limit: Integer; const Offset: Integer): Context<IReadOnlyList<TUser>>;
  end;

implementation

{ TGetAllUsersGateway }

constructor TGetAllUsersGateway.Create(const Query: IGetAllUsersQuery);
begin
  inherited Create;

  FQuery := Utilities.CheckNotNullAndSet(Query, 'Query');
end;


function TGetAllUsersGateway.GetMappedUser(const User: IUserRecord): TUser;
var
  ResultUser: TUser;
begin
  Mappers.Map<IUserRecord, TUser>(User, ResultUser);
  Result := ResultUser;
end;

function TGetAllUsersGateway.Map(const List: IReadOnlyList<IUserRecord>): IReadOnlyList<TUser>;
var
  DestinationList: IList<TUser>;
begin
  DestinationList := TCollections.CreateList<TUser>;

  List.ForEach(
    procedure(const Item: IUserRecord)
    begin
      DestinationList.Add(&Try<IUserRecord>.
        New(Item).
        Map<TUser>(GetMappedUser).
        Match(EGetAllUsersGateway, 'Error mapping users. Error message: %s'));
    end);

  Result := DestinationList.AsReadOnlyList;
end;

function TGetAllUsersGateway.DoGetAll(const Params: TGetAllMappedParams): IReadOnlyList<IUserRecord>;
begin
  Result := FQuery.Open(Params.OrderBy, Params.Limit, Params.Offset);
end;

function TGetAllUsersGateway.Open(const OrderBy: string; const Limit: Integer; const Offset: Integer): Context<IReadOnlyList<TUser>>;
begin
  Result := Context<TGetAllMappedParams>.
    New(TGetAllMappedParams.Create(OrderBy, Limit, Offset)).
    Map<IReadOnlyList<IUserRecord>>(DoGetAll).
    Map<IReadOnlyList<TUser>>(Map);
end;

{ TGetAllUsersGateway.TGetAllMappedParams }

constructor TGetAllUsersGateway.TGetAllMappedParams.Create(
  const OrderBy: string;
  const Limit: Integer;
  const Offset: Integer);
begin
  FOrderBy := OrderBy;
  FLimit := Limit;
  FOffset := Offset;
end;

end.
