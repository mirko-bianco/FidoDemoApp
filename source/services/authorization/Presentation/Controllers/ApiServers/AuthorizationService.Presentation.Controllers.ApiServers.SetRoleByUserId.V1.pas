unit AuthorizationService.Presentation.Controllers.ApiServers.SetRoleByUserId.V1;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Logging,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Types,
  Fido.Logging.Utils,
  Fido.Http.Types,
  Fido.Api.Server.Exceptions,
  Fido.Api.Server.Resource.Attributes,
  Fido.Api.Server.Consul.Resource.Attributes,

  FidoApp.Constants,

  AuthorizationService.Domain.UseCases.SetRoleByUserId.Intf,
  AuthorizationService.Domain.Entities.UserRole;

type
  {$M+}
  [BaseUrl(Constants.API_PREFIX)]
  [Consumes(mtJson)]
  [Produces(mtJson)]
  TSetRoleByUserIdV1ApiServerController = class(TObject)
  private
    FLogger: ILogger;
    FSetRoleByUserIdUseCase: ISetRoleByUserIdUseCase;

    function SetRole(const UserRole: Shared<TUserRole>): Context<Void>;
    function DoSetRole(const UserRole: Shared<TUserRole>): Context<Void>;
  public
    constructor Create(const Logger: ILogger; const SetRoleByUserIdUseCase: ISetRoleByUserIdUseCase);

    [Path(rmPatch, '/1/role/{userid}/{role}')]
    [RequestMiddleware('Authenticated')]
    [RequestMiddleware('Authorized', Constants.PERMISSION_CAN_SET_USER_ROLE)]
    [ResponseMiddleware('ForwardTokens')]
    procedure Execute(const [PathParam] UserId: TGuid; const [PathParam] Role: string);
  end;
  {$M-}

implementation

{ TGetRoleByUserIdV1ApiServerController }

constructor TSetRoleByUserIdV1ApiServerController.Create(
  const Logger: ILogger;
  const SetRoleByUserIdUseCase: ISetRoleByUserIdUseCase);
begin
  inherited Create;

  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
  FSetRoleByUserIdUseCase := Utilities.CheckNotNullAndSet(SetRoleByUserIdUseCase, 'SetRoleByUserIdUseCase');
end;

function TSetRoleByUserIdV1ApiServerController.DoSetRole(const UserRole: Shared<TUserRole>): Context<Void>;
begin
  Result := FSetRoleByUserIdUseCase.Run(UserRole);
end;

function TSetRoleByUserIdV1ApiServerController.SetRole(const UserRole: Shared<TUserRole>): Context<Void>;
begin
  Result := &Try<Shared<TUserRole>>.
    New(UserRole).
    Map<Void>(DoSetRole).
    Match(function(const E: TObject): Void
      begin
        raise EApiServer500.Create((E as Exception).Message, FLogger, ClassName, 'SetRoleByUserId');
      end);
end;

procedure TSetRoleByUserIdV1ApiServerController.Execute(
  const UserId: TGuid;
  const Role: string);
begin
  Logging.LogDuration(
    FLogger,
    ClassName,
    'SetRoleByUserId',
    procedure
    begin
      Context<Shared<TUserRole>>.New(TUserRole.Create(UserId, Role)).Map<Void>(SetRole).Value;
    end);
end;

end.
