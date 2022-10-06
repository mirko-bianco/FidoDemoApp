unit UsersService.Domain.UseCases.GetAll;

interface

uses
  System.SysUtils,
  System.Hash,
  System.RegularExpressions,

  Spring,
  Spring.Collections,

  Fido.Types,
  Fido.Exceptions,
  Fido.Functional,
  Fido.Functional.Tries,

  FidoApp.Types,

  UsersService.Domain.UseCases.GetAll.Intf,
  UsersService.Domain.Repositories.User.Intf,
  UsersService.Domain.Entities.User;

type
  TGetAllUseCase = class(TInterfacedObject, IGetAllUseCase)
  private type
    TGetAllInputParams = record
    private
      FOrderBy: TGetAllUsersOrderBy;
      FLimit: Integer;
      FPage: Integer;

    public
      constructor Create(const OrderBy: TGetAllUsersOrderBy; const Limit: Integer; const Page: Integer);

      property OrderBy: TGetAllUsersOrderBy read FOrderBy;
      property Limit: Integer read FLimit;
      property Page: Integer read FPage;
    end;
  private var
    FRepositoryFactory: TFunc<IUserRepository>;
    function DoGetAll(const Params: TGetAllInputParams): TGetAllV1Result;

  public
    constructor Create(const RepositoryFactory: TFunc<IUserRepository>);

    function Run(const OrderBy: TGetAllUsersOrderBy; const Page: Integer; const Limit: Integer): Context<TGetAllV1Result>;
  end;

implementation

{ TGetAllUseCase }

constructor TGetAllUseCase.Create(const RepositoryFactory: TFunc<IUserRepository>);
begin
  inherited Create;

  Guard.CheckTrue(Assigned(RepositoryFactory), 'RepositoryFactory');

  FRepositoryFactory := RepositoryFactory;
end;

function TGetAllUseCase.DoGetAll(const Params: TGetAllInputParams): TGetAllV1Result;
var
  Repository: IUserRepository;
begin
  Repository := FRepositoryFactory();
  Result := TGetAllV1Result.Create(
    Repository.GetAllCount,
    Repository.GetAll(Params.OrderBy, Params.Limit, Params.Page));
end;

function TGetAllUseCase.Run(
  const OrderBy: TGetAllUsersOrderBy;
  const Page: Integer;
  const Limit: Integer): Context<TGetAllV1Result>;
begin
  Result := &Try<TGetAllInputParams>.
    New(TGetAllInputParams.Create(OrderBy, Limit,  (Page - 1) * Limit)).
    Map<TGetAllV1Result>(DoGetAll).
    Match(function(const E: TObject): TGetAllV1Result
      begin
        if E.InheritsFrom(EUserRepositoryValidation) then
          raise EGetAllUseCaseValidation.Create((E as Exception).Message);
        raise EGetAllUseCaseFailure.Create((E as Exception).Message);
      end);
end;

{ TGetAllUseCase.TGetAllInputParams }

constructor TGetAllUseCase.TGetAllInputParams.Create(
  const OrderBy: TGetAllUsersOrderBy;
  const Limit: Integer;
  const Page: Integer);
begin
  FOrderBy := OrderBy;
  FPage := Page;
  FLimit := Limit;
end;

end.
