unit UsersService.Persistence.Repositories.User;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Collections,

  Fido.Mappers,
  Fido.Exceptions,
  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,

  FidoApp.Types,

  UsersService.Domain.Entities.User,
  UsersService.Domain.Repositories.User.Intf,
  UsersService.Persistence.Gateways.Add.Intf,
  UsersService.Persistence.Gateways.Remove.Intf,
  UsersService.Persistence.Gateways.GetAll.Intf,
  UsersService.Persistence.Gateways.GetCount.Intf,
  UsersService.Persistence.Db.Types;

type
  TUserRepository = class(TInterfacedObject, IUserRepository)
  private type
    TGetAllInputParams = record
    private
      FOrderBy: TGetAllUsersOrderBy;
      FLimit: Integer;
      FOffset: Integer;
    public
      constructor Create(const OrderBy: TGetAllUsersOrderBy; const Limit: Integer; const Offset: Integer);

      property OrderBy: TGetAllUsersOrderBy read FOrderBy;
      property Limit: Integer read FLimit;
      property Offset: Integer read FOffset;
    end;
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
    FInsertGateway: IInsertGateway;
    FDeleteUserGateway: IDeleteUserGateway;
    FGetAllGateway: IGetAllUsersGateway;
    FGetUsersCountGateway: IGetUsersCountGateway;

    function MapParams(const Params: TGetAllInputParams): TGetAllMappedParams;
    function DoGetAllUsers(const Params: TGetAllMappedParams): Context<IReadOnlyList<TUser>>;
    function DoRemove(const Id: TGuid): Context<Integer>;
    function DoVerifyGetAllResult(const Id: TGuid): Context<Integer>.FunctorProc;
    function DoInsertUser(const User: TUser): Context<Integer>;
    function DoVerifyInsertResult(const User: TUser): Context<Integer>.FunctorProc;
  public
    constructor Create(
      const InsertGateway: IInsertGateway;
      const DeleteUserGateway: IDeleteUserGateway;
      const GetAllGateway: IGetAllUsersGateway;
      const GetUsersCountGateway: IGetUsersCountGateway);

    function Store(const User: TUser): Context<Void>;
    function Remove(const Id: TGuid): Context<Void>;
    function GetAll(const OrderBy: TGetAllUsersOrderBy; const Limit: Integer; const Offset: Integer): Context<IReadOnlyList<TUser>>;
    function GetAllCount: Context<Integer>;
  end;

implementation

{ TUserRepository }

constructor TUserRepository.Create(
  const InsertGateway: IInsertGateway;
  const DeleteUserGateway: IDeleteUserGateway;
  const GetAllGateway: IGetAllUsersGateway;
  const GetUsersCountGateway: IGetUsersCountGateway);
begin
  inherited Create;

  FInsertGateway := Utilities.CheckNotNullAndSet(InsertGateway, 'InsertUserCommand');
  FDeleteUserGateway := Utilities.CheckNotNullAndSet(DeleteUserGateway, 'DeleteUserGateway');
  FGetAllGateway := Utilities.CheckNotNullAndSet(GetAllGateway, 'GetAllGateway');
  FGetUsersCountGateway := Utilities.CheckNotNullAndSet(GetUsersCountGateway, 'GetUsersCountGateway');
end;

function TUserRepository.MapParams(const Params: TGetAllInputParams): TGetAllMappedParams;
var
  OrderByStr: string;
begin
  case Params.OrderBy of
    FirstNameAsc: OrderByStr := 'firstname';
    FirstNameDesc: OrderByStr := 'firstname desc';
    LastNameAsc: OrderByStr := 'lastname';
    LastNameDesc: OrderByStr := 'lastname desc';
  else
    raise EUserRepositoryValidation.Create('OrderBy filter is not valid');
  end;

  Result := TGetAllMappedParams.Create(OrderByStr, Params.Limit, Params.Offset);
end;

function TUserRepository.DoGetAllUsers(const Params: TGetAllMappedParams): Context<IReadOnlyList<TUser>>;
begin
  Result := FGetAllGateway.Open(Params.OrderBy, Params.Limit, Params.Offset);
end;

function TUserRepository.GetAll(const OrderBy: TGetAllUsersOrderBy; const Limit: Integer; const Offset: Integer): Context<IReadOnlyList<TUser>>;
begin
  Result := &Try<TGetAllMappedParams>.
    New(Context<TGetAllInputParams>.
    New(TGetAllInputParams.Create(OrderBy, Limit, Offset)).
    Map<TGetAllMappedParams>(MapParams)).
    Map<IReadOnlyList<TUser>>(DoGetAllUsers).
    Match(EUserRepository, 'Error retrieving users. Error message: %s');
end;

function TUserRepository.GetAllCount: Context<Integer>;
begin
  Result := FGetUsersCountGateway.Open;
end;

function TUserRepository.DoRemove(const Id: TGuid): Context<Integer>;
begin
  Result := FDeleteUserGateway.Execute(Id.ToString);
end;

function TUserRepository.DoVerifyGetAllResult(const Id: TGuid): Context<Integer>.FunctorProc;
begin
  Result := procedure(const AffectedRecords: Integer)
    begin
      if AffectedRecords = 0 then
        raise EUserRepository.CreateFmt('User "%s" could not be removed.', [Id.ToString]);
    end;
end;

function TUserRepository.Remove(const Id: TGuid): Context<Void>;
begin
  Result := &Try<TGuid>.
    New(Id).
    Map<Integer>(DoRemove).
    Match(EUserRepository, Format('User "%s" could not be removed. %s', [Id.ToString, 'Error message: %s'])).
    Map<Void>(Void.MapProc<Integer>(DoVerifyGetAllResult(Id)));
end;

function TUserRepository.DoInsertUser(const User: TUser): Context<Integer>;
begin
  Result := FInsertGateway.Execute(User.Id.ToString, User.FirstName, User.LastName);
end;

function TUserRepository.DoVerifyInsertResult(const User: TUser): Context<Integer>.FunctorProc;
begin
  Result := procedure(const AffectedRecords: Integer)
    begin
      if AffectedRecords <> 1 then
        raise EUserRepository.CreateFmt('User "%s %s" could not be stored.', [User.FirstName, User.LastName]);
    end;
end;

function TUserRepository.Store(const User: TUser): Context<Void>;
begin
  Result := &Try<TUser>.
    New(User).
    Map<Integer>(DoInsertUser).
    Match(EUserRepository, Format('User "%s %s" could not be stored. %s', [User.FirstName, User.LastName, 'Error message: %s'])).
    Map<Void>(Void.MapProc<Integer>(DoVerifyInsertResult(User)));
end;

{ TUserRepository.TGetAllInputParams }

constructor TUserRepository.TGetAllInputParams.Create(
  const OrderBy: TGetAllUsersOrderBy;
  const Limit: Integer;
  const Offset: Integer);
begin
  FOrderBy := OrderBy;
  FLimit := Limit;
  FOffset := Offset;
end;

{ TUserRepository.TGetAllMappedParams }

constructor TUserRepository.TGetAllMappedParams.Create(
  const OrderBy: string;
  const Limit: Integer;
  const Offset: Integer);
begin
  FOrderBy := OrderBy;
  FLimit := Limit;
  FOffset := Offset;
end;

initialization
  Mappers.RegisterMapper<IUserRecord, TUser>(procedure(const Source: IUserRecord; var Destination: TUser)
    begin
      Destination.SetId(TGuid.Create(Source.Id));
      Destination.SetFirstName(Source.FirstName);
      Destination.SetLastName(Source.LastName);
      Destination.SetActive(Source.Active = 1);
    end);

end.

