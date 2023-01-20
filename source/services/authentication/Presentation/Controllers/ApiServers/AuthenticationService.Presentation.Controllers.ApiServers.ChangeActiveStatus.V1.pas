unit AuthenticationService.Presentation.Controllers.ApiServers.ChangeActiveStatus.V1;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Exceptions,
  Fido.Types,
  Fido.Http.Types,
  Fido.Api.Server.Exceptions,
  Fido.Api.Server.Resource.Attributes,
  Fido.Api.Server.Consul.Resource.Attributes,

  FidoApp.Constants,

  AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf,
  AuthenticationService.Domain.Entities.UserStatus;

type
  {$M+}
  [BaseUrl(Constants.API_PREFIX)]
  [Consumes(mtJson)]
  [Produces(mtJson)]
  TChangeActiveStatusV1ApiServerController = class(TObject)
  private
    FUseCase: IChangeActiveStatusUseCase;

    function DoChangeStatus(const UserStatus: TUserStatus): Context<Void>;
  public
    constructor Create(const UseCase: IChangeActiveStatusUseCase);

    [Path(rmPatch, '/1/{UserId}/{NewStatus}')]
    [ResponseCode(204, 'No content')]
    [RequestMiddleware('Authenticated')]
    [RequestMiddleware('Authorized', Constants.PERMISSION_CAN_CHANGE_USER_STATE)]
    [ResponseMiddleware('ForwardTokens')]
    procedure Execute(const [PathParam] UserId: TGuid; const [PathParam] NewStatus: Boolean);
  end;
  {$M-}

implementation

{ TChangeActiveStatusV1ApiServerController }

function TChangeActiveStatusV1ApiServerController.DoChangeStatus(const UserStatus: TUserStatus): Context<Void>;
begin
  Result := FUseCase.Run(UserStatus);
end;

procedure TChangeActiveStatusV1ApiServerController.Execute(const UserId: TGuid; const NewStatus: Boolean);
begin
  &Try<TUserStatus>.
    New(TUserStatus.Create(UserId, NewStatus)).
    Map<Void>(DoChangeStatus).
    Match(nil).Value;
end;

constructor TChangeActiveStatusV1ApiServerController.Create(const UseCase: IChangeActiveStatusUseCase);
begin
  inherited Create;

  FUseCase := Utilities.CheckNotNullAndSet(UseCase, 'UseCase');
end;

end.
