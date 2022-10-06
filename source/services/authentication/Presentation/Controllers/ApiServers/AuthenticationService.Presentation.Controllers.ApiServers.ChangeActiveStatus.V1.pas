unit AuthenticationService.Presentation.Controllers.ApiServers.ChangeActiveStatus.V1;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Logging,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Exceptions,
  Fido.Types,
  Fido.Logging.Utils,
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
    FLogger: ILogger;
    FUseCase: IChangeActiveStatusUseCase;

    function DoChangeStatus(const UserStatus: Shared<TUserStatus>): Context<Void>;
  public
    constructor Create(const Logger: ILogger; const UseCase: IChangeActiveStatusUseCase);

    [Path(rmPatch, '/1/{UserId}/{NewStatus}')]
    [RequestMiddleware('Authenticated')]
    [RequestMiddleware('Authorized', Constants.PERMISSION_CAN_CHANGE_USER_STATE)]
    [ResponseMiddleware('ForwardTokens')]
    procedure Execute(const [PathParam] UserId: TGuid; const [PathParam] NewStatus: Boolean);
  end;
  {$M-}

implementation

{ TChangeActiveStatusV1ApiServerController }

function TChangeActiveStatusV1ApiServerController.DoChangeStatus(const UserStatus: Shared<TUserStatus>): Context<Void>;
begin
  Result := FUseCase.Run(UserStatus);
end;

procedure TChangeActiveStatusV1ApiServerController.Execute(const UserId: TGuid; const NewStatus: Boolean);
begin
  Logging.LogDuration(
    FLogger,
    ClassName,
    'Execute',
    procedure
    begin
      &Try<Shared<TUserStatus>>.
        New(TUserStatus.Create(UserId, NewStatus)).
        Map<Void>(DoChangeStatus).
        Match(function(const E: TObject): Void
          begin
            raise EApiServer500.Create((E as Exception).Message, FLogger, ClassName, 'Execute');
          end).Value;
    end);
end;

constructor TChangeActiveStatusV1ApiServerController.Create(const Logger: ILogger; const UseCase: IChangeActiveStatusUseCase);
begin
  inherited Create;

  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
  FUseCase := Utilities.CheckNotNullAndSet(UseCase, 'UseCase');
end;

end.
