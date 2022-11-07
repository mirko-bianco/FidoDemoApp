unit ClientApp.ViewModels.Users;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Threading,

  Spring,
  Spring.Collections,

  Fido.Exceptions,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Types,
  Fido.Boxes,
  Fido.Utilities,
  Fido.DesignPatterns.Observable.Intf,
  Fido.DesignPatterns.Observable.Delegated,
  Fido.Api.Client.Exception,
  Fido.JSON.Marshalling,
  Fido.EventsDriven.Publisher.Intf,

  FidoApp.Types,
  FidoApp.Messages,
  FidoApp.Domain.ClientTokensCache.Intf,

  ClientApp.Types,
  ClientApp.Messages,
  ClientApp.ViewModels.Users.Intf,
  ClientApp.Models.Domain.UseCases.GetAllUsers.Intf;

type
  EUsersViewModel = class(EFidoException);

  TUsersViewModel = class(TDelegatedObservable, IUsersViewModel)
  private type
    TGetAllInputParams = record
    private
      FOrderBy: TGetAllUsersOrderBy;
      FPage: Integer;
      FLimit: Integer;
    public
      constructor Create(const OrderBy: TGetAllUsersOrderBy; const Page: Integer; const Limit: Integer);

      property OrderBy: TGetAllUsersOrderBy read FOrderBy;
      property Page: Integer read FPage;
      property Limit: Integer read FLimit;

    end;
  private var
    FPublisher: IEventsDrivenPublisher;
    FUseCase: IGetAllUsersUseCase;

    FPageNo: IBox<Integer>;
    FItemsPerPage: IBox<Integer>;
    FTotalCount: IBox<Integer>;
    FOrderBy: IBox<TGetAllUsersOrderBy>;
    FUsers: IBox<IReadonlyList<IUser>>;

    procedure ChangeBusyStatus(const Value: Boolean);
    procedure NotifyFailedGetAllUsers(const Message: string);
    procedure NotifySuccededGetAllUsers;
    function DoGetAll(const Params: TGetAllInputParams): Context<IGetAllUsersV1Result>;
    function DoUpdateAndNotify(const Param: IGetAllUsersV1Result): IGetAllUsersV1Result;
    function OnException(const E: TObject): IGetAllUsersV1Result;

  public
    constructor Create(const Publisher: IEventsDrivenPublisher; const GetAllUsersUseCase: IGetAllUsersUseCase);

    function Run: Context<Void>;

    function PagesCount: Integer;
    function ChangePageNumber(const PageNumber: Integer): Context<Void>;
    function PageNumber: Integer;
    function CanPrior: Boolean;
    function Prior: Context<Void>;
    function CanNext: Boolean;
    function Next: Context<Void>;
    function OrderBy: TGetAllUsersOrderBy;
    function ChangeOrderBy(const OrderBy: TGetAllUsersOrderBy): Context<Void>;
    function Users: IReadonlyList<IUser>;

    procedure Close;
  end;

implementation

{ TUsersModelView }

function TUsersViewModel.CanNext: Boolean;
begin
  Result := FPageNo.Value < PagesCount;
end;

function TUsersViewModel.CanPrior: Boolean;
begin
  Result := FPageNo.Value > 1;
end;

procedure TUsersViewModel.ChangeBusyStatus(const Value: Boolean);
begin
  FPublisher.Trigger('UsersViewModel', VIEW_BUSY_MESSAGE, [Value]).Value;
end;

function TUsersViewModel.ChangeOrderBy(const OrderBy: TGetAllUsersOrderBy): Context<Void>;
begin
  if OrderBy = FOrderBy.Value then
    Exit(Void.Get);

  FOrderBy.UpdateValue(OrderBy);
  Result := Run;
end;

function TUsersViewModel.ChangePageNumber(const PageNumber: Integer): Context<Void>;
begin
  if PageNumber = FPageNo.Value then
    Exit(Void.Get);

  if (PageNumber < 1) or (PageNumber > PagesCount) then
    raise EUsersViewModel.Create('Page number is not valid');

  FPageNo.UpdateValue(PageNumber);
  Result := Run;
end;

procedure TUsersViewModel.Close;
begin
  FPublisher.Trigger('UsersViewModel', VIEW_CLOSED_MESSAGE, []).Value;
end;

function TUsersViewModel.Next: Context<Void>;
begin
  if not CanNext then
    raise EUsersViewModel.Create('Page number is not valid');
  FPageNo.UpdateValue(FPageNo.Value + 1);
  Result := Run;
end;

procedure TUsersViewModel.NotifyFailedGetAllUsers(const Message: string);
begin
  FPublisher.Trigger('UsersViewModel', VIEW_GETALLUSERS_FAILED_MESSAGE, [Message]).Value;
end;

procedure TUsersViewModel.NotifySuccededGetAllUsers;
begin
  FPublisher.Trigger('UsersViewModel', VIEW_GETALLUSERS_SUCCEDED_MESSAGE, []).Value;
end;

function TUsersViewModel.OrderBy: TGetAllUsersOrderBy;
begin
  Result := FOrderBy.Value;
end;

function TUsersViewModel.PageNumber: Integer;
begin
  Result := FPageNo.Value;
end;

function TUsersViewModel.PagesCount: Integer;
var
  Tot: Integer;
  Step: Integer;
begin
  Tot := FTotalCount.Value;
  Step := FItemsPerPage.Value;
  Result := (Tot div Step) + Utilities.IfThen<Integer>((Tot mod Step) = 0, 0, 1);
end;

function TUsersViewModel.Prior: Context<Void>;
begin
  if not CanPrior then
    raise EUsersViewModel.Create('Page number is not valid');
  FPageNo.UpdateValue(FPageNo.Value - 1);
  Result := Run;
end;

constructor TUsersViewModel.Create(
  const Publisher: IEventsDrivenPublisher;
  const GetAllUsersUseCase: IGetAllUsersUseCase);
begin
  inherited Create(nil);
  FPublisher := Utilities.CheckNotNullAndSet(Publisher, 'Publisher');
  FUseCase := Utilities.CheckNotNullAndSet(GetAllUsersUseCase, 'UsersUseCase');

  FPageNo := Box<Integer>.Setup(1);
  FItemsPerPage := Box<Integer>.Setup(20);
  FTotalCount := Box<Integer>.Setup(0);
  FOrderBy := Box<TGetAllUsersOrderBy>.Setup(TGetAllUsersOrderBy.FirstNameAsc);
  FUsers := Box<IReadonlyList<IUser>>.Setup(TCollections.CreateList<IUser>.AsReadOnly);
end;

function TUsersViewModel.DoGetAll(const Params: TGetAllInputParams): Context<IGetAllUsersV1Result>;
begin
  Result := FUseCase.Run(Params.OrderBy, Params.Page, Params.Limit);
end;

function TUsersViewModel.DoUpdateAndNotify(const Param: IGetAllUsersV1Result): IGetAllUsersV1Result;
begin
  Result := Param;
  FTotalCount.UpdateValue(Result.Count);
  FUsers.UpdateValue(Result.Users);
  NotifySuccededGetAllUsers;
end;

function TUsersViewModel.OnException(const E: TObject): IGetAllUsersV1Result;
begin
  if E.InheritsFrom(EFidoClientApiException) then
    NotifyFailedGetAllUsers(Format('%d: %s', [(E as EFidoClientApiException).ErrorCode, (E as EFidoClientApiException).ErrorMessage]));
end;

function TUsersViewModel.Run: Context<Void>;
var
  Func: TFunc<Void>;
begin
  Func := function: Void
    begin
      Context<Boolean>.
        New(True).
        Map<Void>(Void.MapProc<Boolean>(ChangeBusyStatus));

      Result := Void.Map<IGetAllUsersV1Result>(&Try<IGetAllUsersV1Result>.
          New(&Try<TGetAllInputParams>.
          New(TGetAllInputParams.Create(FOrderBy.Value, FPageNo.Value, FItemsPerPage.Value)).
          Map<IGetAllUsersV1Result>(DoGetAll).
          Match(OnException)).
        Map<IGetAllUsersV1Result>(DoUpdateAndNotify).
        Match(OnException, procedure
          begin
            Context<Boolean>.New(False).Map<Void>(Void.MapProc<Boolean>(ChangeBusyStatus)).Value;
          end));
    end;

  Result := Context<Void>.New(Func);
end;

function TUsersViewModel.Users: IReadonlyList<IUser>;
begin
  Result := FUsers.Value;
end;

{ TUsersViewModel.TGetAllInputParams }

constructor TUsersViewModel.TGetAllInputParams.Create(
  const OrderBy: TGetAllUsersOrderBy;
  const Page: Integer;
  const Limit: Integer);
begin
  FOrderBy := OrderBy;
  FPage := Page;
  FLimit := Limit;
end;

end.
