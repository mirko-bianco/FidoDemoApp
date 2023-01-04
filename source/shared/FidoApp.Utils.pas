unit FidoApp.Utils;

interface

uses
  System.SysUtils,
  System.JSON,
  System.NetEncoding,

  FireDac.Comp.Client,

  JOSE.Core.JWT,

  Spring,
  Spring.Logging,
  Spring.Collections,

  Fido.Types,
  Fido.Http.Types,
  Fido.Api.Server.Intf,
  Fido.EventsDriven,
  Fido.JWT.Manager.Intf,
  Fido.Http.Request.Intf,
  Fido.Http.Response.Intf,
  Fido.Db.Connections.FireDac,
  Fido.Db.Migrations.Model.Intf,
  Fido.JSON.Marshalling,
  Fido.Logging.Utils,

  FidoApp.Types,
  FidoApp.Constants,
  FidoApp.Domain.ClientTokensCache.Intf;

type
  TGetUserRoleFunc = reference to function(const Authorization: string; const RefreshToken: string): IUserRoleAndPermissions;
  TRefreshTokensFunc = reference to function(const CurrentRefreshToken: string; out Authorization: string; out RefreshToken: string): Boolean;

  Utils = record
  type
    Files = record
      class function GetLogFilename: string; static;
      class function GetIniFilename: string; static;
    end;
    DbMigrations = record
      class procedure Run(const MigrationsModel: IDatabaseMigrationsModel; const DatabaseName: string); static;
    end;
    Apis = record
    type
      Server = record
      type
        Middlewares = record
        private
          class function ValidateToken(const JWTManager: IJWTManager; const VerificationKey: string; const Token: string; const ClaimType: string; out ResponseCode: Integer; out ResponseText: string;
            out IsExpired: Boolean): Boolean; static;
        public
          class function GetAuthenticated(const JWTManager: IJWTManager; const VerificationKey: string; const RefreshTokenFunc: TRefreshTokensFunc): TApiRequestMiddlewareFunc; static;
          class function GetAuthorized(const GetUserRoleFunc: TGetUserRoleFunc): TApiRequestMiddlewareFunc; static;
          class function GetForwardTokens: TApiResponseMiddlewareProc; static;
          class function GetLogged(const Logger: ILogger): TApiGlobalMiddlewareProc; static;

          class procedure Register(const Server: IApiServer; const Logger: ILogger; const JWTManager: IJWTManager; const VerificationKey: string; const RefreshTokensFunc: TRefreshTokensFunc;
            const GetUserRoleFunc: TGetUserRoleFunc); static;
        end;
        Jwt = record
          class function ExtractUserRoleAndPermissions(const AuthenticationToken: string): IUserRoleAndPermissions; static;
        end;
      end;
    end;
    Consumers = record
    type
      Middlewares = record
        class function GetLogged(const Logger: ILogger): TEventDrivenGlobalMiddlewareProc; static;
      end;
    end;
  type
    Permissions = record
      class function Can(const Permissions: IReadOnlyList<Permission>; const Action: Permission): Boolean; static;
      class function TryGetFromLabel(const &Label: string; out Perm: Permission): Boolean; static;
    end;

  end;

implementation

{ Utils }

class function Utils.Files.GetIniFilename: string;
begin
  Result := ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');
end;

class function Utils.Files.GetLogFilename: string;
begin
  Result := ChangeFileExt(ExtractFileName(ParamStr(0)), '.log');
end;

class procedure Utils.DbMigrations.Run(
  const MigrationsModel: IDatabaseMigrationsModel;
  const DatabaseName: string);
begin
  MigrationsModel.ExecSQL(Format('create database if not exists %s;', [DatabaseName]));
  MigrationsModel.ExecSQL(Format('create table if not exists %s.dbmigrations (filename varchar(100) unique not null);', [DatabaseName]));

  MigrationsModel.Run;
end;

{ Utils.Apis.Server.Middlewares }

class function Utils.Apis.Server.Middlewares.ValidateToken(
  const JWTManager: IJWTManager;
  const VerificationKey: string;
  const Token: string;
  const ClaimType: string;
  out ResponseCode: Integer;
  out ResponseText: string;
  out IsExpired: Boolean): Boolean;
var
  JWT: Shared<TJwt>;
begin
  IsExpired := False;
  Result := False;

  JWT := JWTManager.VerifyToken(Token, VerificationKey);
  if not Assigned(JWT.Value) then
  begin
    ResponseCode := 400;
    Exit;
  end;

  if not Assigned(JWT.Value.Claims.JSON.GetValue(Constants.CLAIM_TYPE)) then
  begin
    ResponseCode := 401;
    Exit;
  end;

  if not JWT.Value.Claims.JSON.GetValue(Constants.CLAIM_TYPE).ToString.DeQuotedString('"').Equals(ClaimType) then
  begin
    ResponseCode := 401;
    Exit;
  end;

  if not JWT.Value.Verified then
  begin
    ResponseCode := 401;
    Exit;
  end;

  if not JWT.Value.Claims.JSON.GetValue(Constants.CLAIM_TYPE).ToString.DeQuotedString('"').Equals(Constants.CLAIM_TYPE_REFRESH) and
    (JWT.Value.Claims.Expiration < Now) then
  begin
    IsExpired := True;
    ResponseCode := 401;
    Exit;
  end;

  Result := True;
end;

class function Utils.Apis.Server.Middlewares.GetAuthenticated(
  const JWTManager: IJWTManager;
  const VerificationKey: string;
  const RefreshTokenFunc: TRefreshTokensFunc): TApiRequestMiddlewareFunc;
begin
  Result :=
    function(const CommaSeparatedParams: string; const ApiRequest: IHttpRequest; out ResponseCode: Integer; out ResponseText: string): Boolean
    var
      CompactAccessToken: string;
      CompactRefreshToken: string;
      IsExpired: Boolean;
    begin
      Result := False;

      CompactAccessToken := ApiRequest.HeaderParams.GetValueOrDefault(Constants.HEADER_AUTHORIZATION);
      CompactRefreshToken := ApiRequest.HeaderParams.GetValueOrDefault(Constants.HEADER_REFRESHTOKEN);

      if not CompactAccessToken.StartsWith('Bearer ', True) then
      begin
        ResponseCode := 400;
        Exit;
      end;

      if ValidateToken(JWTManager, VerificationKey, CompactAccessToken.Replace('Bearer ', ''), Constants.CLAIM_TYPE_ACCESS, ResponseCode, ResponseText, IsExpired) then
      begin
        // Update request Authorization and Refresh-Token headers
        ApiRequest.HeaderParams.Items[Constants.HEADER_AUTHORIZATION] := CompactAccessToken;
        ApiRequest.HeaderParams.Items[Constants.HEADER_REFRESHTOKEN] := CompactRefreshToken;
        Exit(True)
      end
      else if not IsExpired then
        Exit
      else if not ValidateToken(JWTManager, VerificationKey, CompactRefreshToken, Constants.CLAIM_TYPE_REFRESH, ResponseCode, ResponseText, IsExpired) then
        Exit;

      // Refresh the tokens if access token is expired
      if not RefreshTokenFunc(CompactRefreshToken, CompactAccessToken, CompactRefreshToken) then
      begin
        ResponseCode := 401;
        Exit;
      end;

      // Update request Authorization and Refresh-Token headers
      ApiRequest.HeaderParams.Items[Constants.HEADER_AUTHORIZATION] := CompactAccessToken;
      ApiRequest.HeaderParams.Items[Constants.HEADER_REFRESHTOKEN] := CompactRefreshToken;
      Result := True;
    end;
end;

class function Utils.Apis.Server.Middlewares.GetAuthorized(const GetUserRoleFunc: TGetUserRoleFunc): TApiRequestMiddlewareFunc;
var
  Authorized: Boolean;
  RequiredPermission: Permission;
begin
  Result :=
    function(const CommaSeparatedParams: string; const ApiRequest: IHttpRequest; out ResponseCode: Integer; out ResponseText: string): Boolean
    var
      CompactAccessToken: string;
      CompactRefreshToken: string;
      AuthResult: IUserRoleAndPermissions;
    begin
      Result := False;

      CompactAccessToken := ApiRequest.HeaderParams.GetValueOrDefault(Constants.HEADER_AUTHORIZATION);
      if not CompactAccessToken.StartsWith('Bearer ', True) then
      begin
        ResponseCode := 400;
        Exit;
      end;

      CompactRefreshToken := ApiRequest.HeaderParams.GetValueOrDefault(Constants.HEADER_REFRESHTOKEN);

      try
        AuthResult := GetUserRoleFunc(CompactAccessToken, CompactRefreshToken);
      except
        on E: Exception do
        begin
          ResponseCode := 401;
          Exit;
        end;
      end;

      Authorized := False;
      if Utils.Permissions.TryGetFromLabel(CommaSeparatedParams, RequiredPermission) then
        Authorized := Utils.Permissions.Can(AuthResult.Permissions, RequiredPermission);

      if not Authorized then
      begin
        ResponseCode := 403;
        Exit;
      end;

      Result := True;
    end;
end;

class function Utils.Apis.Server.Middlewares.GetForwardTokens: TApiResponseMiddlewareProc;
begin
  Result :=
    procedure(const CommaSeparaterParams: string; const ApiRequest: IHttpRequest; const ApiResponse: IHttpResponse)
    begin
      ApiResponse.HeaderParams[Constants.HEADER_AUTHORIZATION] := ApiRequest.HeaderParams.GetValueOrDefault(Constants.HEADER_AUTHORIZATION);
      ApiResponse.HeaderParams[Constants.HEADER_REFRESHTOKEN] := ApiRequest.HeaderParams.GetValueOrDefault(Constants.HEADER_REFRESHTOKEN);
    end;
end;

class function Utils.Apis.Server.Middlewares.GetLogged(const Logger: ILogger): TApiGlobalMiddlewareProc;
begin
  Result := procedure(const EndpointMethod: Action; const ClassName: string; const MethodName: string)
    begin
      Logging.LogDuration(
        Logger,
        ClassName,
        MethodName,
        EndPointMethod);
    end;
end;

class procedure Utils.Apis.Server.Middlewares.Register(
  const Server: IApiServer;
  const Logger: ILogger;
  const JWTManager: IJWTManager;
  const VerificationKey: string;
  const RefreshTokensFunc: TRefreshTokensFunc;
  const GetUserRoleFunc: TGetUserRoleFunc);
begin
  Server.RegisterRequestMiddleware(
    'Authenticated',
    Utils.Apis.Server.Middlewares.GetAuthenticated(JWTManager, VerificationKey, RefreshTokensFunc));

  Server.RegisterRequestMiddleware(
    'Authorized',
    Utils.Apis.Server.Middlewares.GetAuthorized(GetUserRoleFunc));

  Server.RegisterResponseMiddleware(
    'ForwardTokens',
    Utils.Apis.Server.Middlewares.GetForwardTokens());
  Server.RegisterGlobalMiddleware(Utils.Apis.Server.Middlewares.GetLogged(Logger))
end;

{ Utils.Apis.Server.Jwt }

class function Utils.Apis.Server.Jwt.ExtractUserRoleAndPermissions(const AuthenticationToken: string): IUserRoleAndPermissions;
var
  EncodedClaims: string;
  Claims: string;
begin
  EncodedClaims := AuthenticationToken.Split(['.'])[1];

  Claims := TNetEncoding.Base64String.Decode(EncodedClaims);

  Result := JSONUnmarshaller.To<IUserRoleAndPermissions>(Claims);
end;

{ Utils.Permissions }

class function Utils.Permissions.Can(const Permissions: IReadOnlyList<Permission>; const Action: Permission): Boolean;
var
  Item: Permission;
begin
  Result := False;
  for Item in Permissions do
    if Item = Action then
      Exit(True);
end;

class function Utils.Permissions.TryGetFromLabel(const &Label: string; out Perm: Permission): Boolean;
var
  Index: Integer;
begin
  Result := False;
  Index := TCollections.CreateList<string>(Constants.SPermission).IndexOf(&Label);
  if Index = -1 then
    Exit;
  Perm := Permission(Index);
  Result := True;
end;

{ Utils.Consumers.Middlewares }

class function Utils.Consumers.Middlewares.GetLogged(const Logger: ILogger): TEventDrivenGlobalMiddlewareProc;
begin
  Result := procedure(const ConsumerMethod: Action; const ClassName: string; const MethodName: string)
    begin
      Logging.LogDuration(
        Logger,
        ClassName,
        MethodName,
        ConsumerMethod);
    end;
end;

end.
