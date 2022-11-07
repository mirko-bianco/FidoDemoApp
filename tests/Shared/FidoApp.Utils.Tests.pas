unit FidoApp.Utils.Tests;

interface

uses
  System.SysUtils,
  System.JSON,
  System.NetEncoding,
  IdCustomHTTPServer,
  IdContext,
  FireDAC.Comp.Client,

  DUnitX.TestFramework,

  JOSE.Core.JWT,
  JOSE.Types.Bytes,

  Spring,
  Spring.Collections,
  Spring.Mocking,

  Fido.Types,
  Fido.Exceptions,
  Fido.Db.Connections.FireDac,
  Fido.Db.Migrations.Model.Intf,
  Fido.Api.Server.Intf,
  Fido.Http.Request.Intf,
  Fido.Http.Response.Intf,
  Fido.Http.Request,
  Fido.Http.Response,
  Fido.JWT.Manager.Intf,
  Fido.Testing.Mock.Utils,
  Fido.DesignPatterns.Adapter.TIdHTTPRequestInfoAsIHTTPRequestInfo,
  Fido.Http.RequestInfo.Intf,
  Fido.DesignPatterns.Adapter.TIdHTTPResponseInfoAsIHTTPResponseInfo,
  Fido.Http.ResponseInfo.Intf,

  FidoApp.Types,
  FidoApp.Constants,
  FidoApp.Utils,
  FidoApp.Domain.UseCases.RefreshToken.Intf;

type
  EFidoAppUtilsTests = class(EFidoException);

  [TestFixture]
  TFidoAppUtilsTests = class
  public
    [Test]
    procedure GetAuthenticatedReturnsTrueWhenUserIsAuthenticated;

    [Test]
    procedure GetAuthenticatedReturnsFalseAnd400WhenAccessTokenDoesNotStartWithBearer;

    [Test]
    procedure GetAuthenticatedReturnsFalseAnd400WhenAccessTokenCannotBeVerified;

    [Test]
    procedure GetAuthenticatedReturnsFalseAnd400WhenAccessTokenDoesNotContainClaimType;

    [Test]
    procedure GetAuthenticatedReturnsFalseAnd400WhenAccessTokenDoesContainsWrongClaimType;

    [Test]
    procedure GetAuthenticatedReturnsFalseAnd401WhenJwtIsNotVerified;

    [Test]
    procedure GetAuthenticatedReturnsFalseAnd401WhenRefreshTokenFuncReturnsFalse;

    [Test]
    procedure GetAuthenticatedReturnsTrueWhenRefreshTokenFuncReturnsTrue;

    [Test]
    procedure GetAuthorizedReturnsTrueWhenUserIsAuthorized;

    [Test]
    procedure GetAuthorizedReturnsFalseAnd400WhenTokenDoesNotStartWithBearer;

    [Test]
    procedure GetAuthorizedReturnsFalseAnd401WhenAuthFuncRaisesAnException;

    [Test]
    procedure GetAuthorizedReturnsFalseAnd403WhenUserHasNoPermission;

    [Test]
    procedure GetAuthenticatedReturnsFalseAnd400WhenAccessJwtsIsExpiredAndRefreshJwtIsInvalid;

    [Test]
    procedure GetAuthenticatedReturnsFalseAnd401WhenAccessJwtsIsExpiredAndRefreshTokenCannotBeVerified;

    [Test]
    procedure GetAuthenticatedReturnsFalseAnd401WhenAccessJwtsIsExpiredAndRefreshTokenDoesNotContainClaim;

    [Test]
    procedure GetAuthenticatedReturnsFalseAnd401WhenAccessJwtsIsExpiredAndRefreshTokenContainsWrongClaimType;

    [Test]
    procedure GetIniFilenameReturnsExecutableNameWithIniExtension;

    [Test]
    procedure GetLogFilenameReturnsExecutableNameWithLogExtension;

    [Test]
    procedure GetForwardTokensPassesTokensFromRequestToResponse;

    [Test]
    procedure TestUtilsApisServerMiddlewaresRegister;

    [Test]
    procedure TestUtilsDbMigrationsRun;

    [Test]
    procedure TestUtilsApisServerJwtExtractUserRoleAndPermissions;
  end;

implementation

{ TFidoAppUtilsTests }

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsFalseAnd400WhenAccessTokenCannotBeVerified;
var
  JWTManager: Mock<IJWTManager>;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>(nil).When.VerifyToken(Arg.IsAny<string>, Arg.IsAny<TJOSEBytes>);


  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(JWTManager, MockUtils.SomeString, nil);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams[Constants.HEADER_AUTHORIZATION] := Format('Bearer %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(400, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsFalseAnd400WhenAccessTokenDoesNotStartWithBearer;
var
  JWTManager: Mock<IJWTManager>;

  Jwt: TJWT;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  JWT := TJWT.Create;

  JWT.Verified := True;
  JWT.Claims.Expiration := Now + 1;

  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>(JWT).When.VerifyToken(Arg.IsAny<string>, Arg.IsAny<TJOSEBytes>);


  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(JWTManager, MockUtils.SomeString, nil);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams[Constants.HEADER_AUTHORIZATION] := Format('somethingelse %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(400, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsFalseAnd400WhenAccessTokenDoesContainsWrongClaimType;
var
  JWTManager: Mock<IJWTManager>;

  Jwt: TJWT;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  JWT := TJWT.Create;

  JWT.Verified := True;
  JWT.Claims.Expiration := Now + 1;
  JWT.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);

  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>(JWT).When.VerifyToken(Arg.IsAny<string>, Arg.IsAny<TJOSEBytes>);

  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(JWTManager, MockUtils.SomeString, nil);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(401, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsFalseAnd400WhenAccessTokenDoesNotContainClaimType;
var
  JWTManager: Mock<IJWTManager>;

  Jwt: TJWT;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  JWT := TJWT.Create;

  JWT.Verified := True;
  JWT.Claims.Expiration := Now + 1;

  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>(JWT).When.VerifyToken(Arg.IsAny<string>, Arg.IsAny<TJOSEBytes>);

  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(JWTManager, MockUtils.SomeString, nil);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(401, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsFalseAnd400WhenAccessJwtsIsExpiredAndRefreshJwtIsInvalid;
var
  JWTManager: Mock<IJWTManager>;

  AccessCompactToken: string;
  RefreshCompactToken: string;
  AccessJwt: TJWT;
  Secret: TJOSEBytes;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  Secret := MockUtils.SomeString;

  AccessCompactToken := MockUtils.SomeString;

  AccessJwt := TJWT.Create;
  AccessJwt.Verified := True;
  AccessJwt.Claims.Expiration := Now - 1;
  AccessJwt.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_ACCESS);

  RefreshCompactToken := MockUtils.SomeString;

  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>(AccessJwt).When.VerifyToken(AccessCompactToken, Secret);
  JWTManager.Setup.Returns<TJWT>(nil).When.VerifyToken(RefreshCompactToken, Secret);

  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(JWTManager, Secret, nil);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [AccessCompactToken]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := RefreshCompactToken;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(400, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsFalseAnd401WhenAccessJwtsIsExpiredAndRefreshTokenCannotBeVerified;
var
  JWTManager: Mock<IJWTManager>;

  AccessCompactToken: string;
  RefreshCompactToken: string;
  AccessJwt: TJWT;
  RefreshJwt: TJWT;
  Secret: TJOSEBytes;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  Secret := MockUtils.SomeString;

  AccessCompactToken := MockUtils.SomeString;

  AccessJwt := TJWT.Create;
  AccessJwt.Verified := True;
  AccessJwt.Claims.Expiration := Now - 1;
  AccessJwt.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_ACCESS);

  RefreshCompactToken := MockUtils.SomeString;

  RefreshJwt := TJWT.Create;
  RefreshJwt.Verified := False;
  RefreshJwt.Claims.Expiration := Now - 1;
  RefreshJwt.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);

  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>(AccessJwt).When.VerifyToken(AccessCompactToken, Secret);
  JWTManager.Setup.Returns<TJWT>(RefreshJwt).When.VerifyToken(RefreshCompactToken, Secret);

  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(JWTManager, Secret, nil);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [AccessCompactToken]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := RefreshCompactToken;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(401, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsFalseAnd401WhenAccessJwtsIsExpiredAndRefreshTokenContainsWrongClaimType;
var
  JWTManager: Mock<IJWTManager>;

  AccessCompactToken: string;
  RefreshCompactToken: string;
  AccessJwt: TJWT;
  RefreshJwt: TJWT;
  Secret: TJOSEBytes;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  Secret := MockUtils.SomeString;

  AccessCompactToken := MockUtils.SomeString;

  AccessJwt := TJWT.Create;
  AccessJwt.Verified := True;
  AccessJwt.Claims.Expiration := Now - 1;
  AccessJwt.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_ACCESS);

  RefreshCompactToken := MockUtils.SomeString;

  RefreshJwt := TJWT.Create;
  RefreshJwt.Verified := False;
  RefreshJwt.Claims.Expiration := Now - 1;
  RefreshJwt.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, 'wrong');

  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>(AccessJwt).When.VerifyToken(AccessCompactToken, Secret);
  JWTManager.Setup.Returns<TJWT>(RefreshJwt).When.VerifyToken(RefreshCompactToken, Secret);

  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(JWTManager, Secret, nil);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [AccessCompactToken]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := RefreshCompactToken;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(401, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsFalseAnd401WhenAccessJwtsIsExpiredAndRefreshTokenDoesNotContainClaim;
var
  JWTManager: Mock<IJWTManager>;

  AccessCompactToken: string;
  RefreshCompactToken: string;
  AccessJwt: TJWT;
  RefreshJwt: TJWT;
  Secret: TJOSEBytes;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  Secret := MockUtils.SomeString;

  AccessCompactToken := MockUtils.SomeString;

  AccessJwt := TJWT.Create;
  AccessJwt.Verified := True;
  AccessJwt.Claims.Expiration := Now - 1;
  AccessJwt.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_ACCESS);

  RefreshCompactToken := MockUtils.SomeString;

  RefreshJwt := TJWT.Create;
  RefreshJwt.Verified := True;
  RefreshJwt.Claims.Expiration := Now - 1;

  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>(AccessJwt).When.VerifyToken(AccessCompactToken, Secret);
  JWTManager.Setup.Returns<TJWT>(RefreshJwt).When.VerifyToken(RefreshCompactToken, Secret);

  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(JWTManager, Secret, nil);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [AccessCompactToken]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := RefreshCompactToken;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(401, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsFalseAnd401WhenJwtIsNotVerified;
var
  JWTManager: Mock<IJWTManager>;

  Jwt: TJWT;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  JWT := TJWT.Create;

  JWT.Verified := False;
  JWT.Claims.Expiration := Now + 1;
  JWT.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_ACCESS);

  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>(JWT).When.VerifyToken(Arg.IsAny<string>, Arg.IsAny<TJOSEBytes>);

  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(JWTManager, MockUtils.SomeString, nil);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(401, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsFalseAnd401WhenRefreshTokenFuncReturnsFalse;
var
  JWTManager: Mock<IJWTManager>;

  ExpiredAccessJwt: TJWT;
  RefreshJwt: TJWT;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  ExpiredAccessJwt := TJWT.Create;

  ExpiredAccessJwt.Verified := True;
  ExpiredAccessJwt.Claims.Expiration := Now - 1;
  ExpiredAccessJwt.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_ACCESS);

  RefreshJwt := TJWT.Create;

  RefreshJwt.Verified := True;
  RefreshJwt.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);

  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>([ExpiredAccessJwt, RefreshJwt]).When.VerifyToken(Arg.IsAny<string>, Arg.IsAny<TJOSEBytes>);

  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(
    JWTManager,
    MockUtils.SomeString,
    function(const CurrentRefreshToken: string; out Authorization: string; out RefreshToken: string): Boolean
    begin
      Result := False;
    end);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(401, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsTrueWhenRefreshTokenFuncReturnsTrue;
var
  JWTManager: Mock<IJWTManager>;

  ExpiredAccessJwt: TJWT;
  RefreshJwt: TJWT;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  ExpiredAccessJwt := TJWT.Create;

  ExpiredAccessJwt.Verified := True;
  ExpiredAccessJwt.Claims.Expiration := Now - 1;
  ExpiredAccessJwt.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_ACCESS);

  RefreshJwt := TJWT.Create;

  RefreshJwt.Verified := True;
  RefreshJwt.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_REFRESH);

  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>([ExpiredAccessJwt, RefreshJwt]).When.VerifyToken(Arg.IsAny<string>, Arg.IsAny<TJOSEBytes>);

  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(
    JWTManager,
    MockUtils.SomeString,
    function(const CurrentRefreshToken: string; out Authorization: string; out RefreshToken: string): Boolean
    begin
      Result := True;
      Authorization := MockUtils.SomeString;
      RefreshToken := MockUtils.SomeString;
    end);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(True, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
end;

procedure TFidoAppUtilsTests.GetAuthenticatedReturnsTrueWhenUserIsAuthenticated;
var
  JWTManager: Mock<IJWTManager>;

  Jwt: TJWT;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  JWT := TJWT.Create;

  JWT.Verified := True;
  JWT.Claims.Expiration := Now + 1;
  JWT.Claims.SetClaimOfType<string>(Constants.CLAIM_TYPE, Constants.CLAIM_TYPE_ACCESS);

  JWTManager := Mock<IJWTManager>.Create;
  JWTManager.Setup.Returns<TJWT>(JWT).When.VerifyToken(Arg.IsAny<string>, Arg.IsAny<TJOSEBytes>);

  Func := Utils.Apis.Server.Middlewares.GetAuthenticated(JWTManager, MockUtils.SomeString, nil);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(True, Func('', ApiRequest, ResponseCode, ResponseText), 'Func('''', ApiRequest, ResponseCode, ResponseText)');
    end);
end;

procedure TFidoAppUtilsTests.GetAuthorizedReturnsFalseAnd400WhenTokenDoesNotStartWithBearer;
var
  GetUserRoleFunc: TGetUserRoleFunc;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  GetUserRoleFunc :=
    function(const Authorization: string; const RefreshToken: string): IUserRoleAndPermissions
    begin
      Result := nil;
    end;

  Func := Utils.Apis.Server.Middlewares.GetAuthorized(GetUserRoleFunc);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('somethingelse %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('CanDoThat', ApiRequest, ResponseCode, ResponseText), 'Func(''CanDoThat'', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(400, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthorizedReturnsFalseAnd401WhenAuthFuncRaisesAnException;
var
  GetUserRoleFunc: TGetUserRoleFunc;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  GetUserRoleFunc :=
    function(const Authorization: string; const RefreshToken: string): IUserRoleAndPermissions
    begin
      raise EFidoAppUtilsTests.Create('Error Message');
    end;

  Func := Utils.Apis.Server.Middlewares.GetAuthorized(GetUserRoleFunc);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('CanDoThat', ApiRequest, ResponseCode, ResponseText), 'Func(''CanDoThat'', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(401, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthorizedReturnsFalseAnd403WhenUserHasNoPermission;
var
  GetUserRoleFunc: TGetUserRoleFunc;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  GetUserRoleFunc :=
    function(const Authorization: string; const RefreshToken: string): IUserRoleAndPermissions
    var
      UserRole: Mock<IUserRoleAndPermissions>;
    begin
      UserRole := Mock<IUserRoleAndPermissions>.Create;
      UserRole.Setup.Returns<string>('user').When.Role;
      UserRole.Setup.Returns<IReadonlyList<string>>(TCollections.CreateList<string>(['CanDoThis', 'CanDoThat']).AsReadOnly).When.Permissions;

      Result := UserRole;
    end;

  Func := Utils.Apis.Server.Middlewares.GetAuthorized(GetUserRoleFunc);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(False, Func('CantDoShit', ApiRequest, ResponseCode, ResponseText), 'Func(''CantDoShit'', ApiRequest, ResponseCode, ResponseText)');
    end);
  Assert.AreEqual(403, ResponseCode, 'ResponseCode');
end;

procedure TFidoAppUtilsTests.GetAuthorizedReturnsTrueWhenUserIsAuthorized;
var
  GetUserRoleFunc: TGetUserRoleFunc;

  Func: TRequestMiddlewareFunc;
  ApiRequest: Mock<IHttpRequest>;
  HeaderParams: IDictionary<string, string>;
  ResponseCode: Integer;
  ResponseText: string;
begin
  GetUserRoleFunc :=
    function(const Authorization: string; const RefreshToken: string): IUserRoleAndPermissions
    var
      UserRole: Mock<IUserRoleAndPermissions>;
    begin
      UserRole := Mock<IUserRoleAndPermissions>.Create;
      UserRole.Setup.Returns<string>('user').When.Role;
      UserRole.Setup.Returns<IReadonlyList<Permission>>(TCollections.CreateList<Permission>([Permission.CanChangeUserState, Permission.CanSetUserRole]).AsReadOnly).When.Permissions;

      Result := UserRole;
    end;

  Func := Utils.Apis.Server.Middlewares.GetAuthorized(GetUserRoleFunc);

  HeaderParams := TCollections.CreateDictionary<string, string>;
  HeaderParams['Authorization'] := Format('Bearer %s', [MockUtils.SomeString]);
  HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;
  ApiRequest := Mock<IHttpRequest>.Create;
  ApiRequest.Setup.Returns<IReadonlyDictionary<string, string>>(HeaderParams.AsReadOnly).When.HeaderParams;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Assert.AreEqual(True, Func(Constants.SPermission[Permission.CanChangeUserState], ApiRequest, ResponseCode, ResponseText), 'Func(Permission.CanChangeUserState, ApiRequest, ResponseCode, ResponseText)');
    end);
end;

procedure TFidoAppUtilsTests.GetForwardTokensPassesTokensFromRequestToResponse;
var
  IdContext: TIdContext;
  IdRequestInfo: TIdHTTPRequestInfo;
  HttpRequestInfo: IHTTPRequestInfo;
  Request: IHttpRequest;
  Response: IHttpResponse;
begin
  IdContext := TIdContext.Create(nil, nil);
  IdRequestInfo := TIdHTTPRequestInfo.Create(nil);
  HttpRequestInfo := TIdHTTPRequestInfoAsIHTTPRequestInfoDecorator.Create(IdRequestInfo);
  Request := THttpRequest.Create(HttpRequestInfo);
  Response := THttpResponse.Create(
    HttpRequestInfo,
    TIdHTTPResponseInfoAsIHTTPResponseInfoDecorator.Create(IdContext, IdRequestInfo, TIdHTTPResponseInfo.Create(nil, IdRequestInfo, nil)));

  Request.HeaderParams[Constants.HEADER_AUTHORIZATION] := MockUtils.SomeString;
  Request.HeaderParams[Constants.HEADER_REFRESHTOKEN] := MockUtils.SomeString;

  Utils.Apis.Server.Middlewares.GetForwardTokens()('', Request, Response);

  Assert.AreEqual(Request.HeaderParams[Constants.HEADER_AUTHORIZATION], Response.HeaderParams[Constants.HEADER_AUTHORIZATION], 'Response.HeaderParams[Constants.HEADER_AUTHORIZATION]');
  Assert.AreEqual(Request.HeaderParams[Constants.HEADER_REFRESHTOKEN], Response.HeaderParams[Constants.HEADER_REFRESHTOKEN], 'Response.HeaderParams[Constants.HEADER_REFRESHTOKEN]');
end;

procedure TFidoAppUtilsTests.GetIniFilenameReturnsExecutableNameWithIniExtension;
var
  IniName: string;
begin
  Ininame := ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');
  Assert.AreEqual(IniName, Utils.Files.GetIniFilename, 'Utils.Files.GetIniFilename');
end;

procedure TFidoAppUtilsTests.GetLogFilenameReturnsExecutableNameWithLogExtension;
var
  LogName: string;
begin
  LogName := ChangeFileExt(ExtractFileName(ParamStr(0)), '.log');
  Assert.AreEqual(LogName, Utils.Files.GetLogFilename, 'Utils.Files.GetLogFilename');
end;

procedure TFidoAppUtilsTests.TestUtilsApisServerJwtExtractUserRoleAndPermissions;
var
  Authentication: string;
  Result: IUserRoleAndPermissions;
begin
  Authentication := Format('%s.%s.%s', [MockUtils.SomeString, TNetEncoding.Base64String.Encode('{"Role": "user", "Permissions": [0, 1]}'), MockUtils.SomeString]);

  Assert.WillNotRaiseAny(
    procedure
    begin
      Result := Utils.Apis.Server.Jwt.ExtractUserRoleAndPermissions(Authentication);
    end);
  Assert.AreEqual('user', Result.Role);
  Assert.AreEqual(2, Result.Permissions.Count);
  Assert.AreEqual(Permission.CanChangeUserState, Result.Permissions[0]);
  Assert.AreEqual(Permission.CanSetUserRole, Result.Permissions[1]);
end;

procedure TFidoAppUtilsTests.TestUtilsApisServerMiddlewaresRegister;
var
  ApiServer: Mock<IApiServer>;
  JwtManager: Mock<IJwtManager>;

begin
  ApiServer := Mock<IApiServer>.Create;
  JwtManager := Mock<IJwtManager>.Create;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Utils.Apis.Server.Middlewares.Register(ApiServer, JwtManager, MockUtils.SomeString, nil, nil);
    end);
end;

procedure TFidoAppUtilsTests.TestUtilsDbMigrationsRun;
var
  MigrationsModel: Mock<IDatabaseMigrationsModel>;
begin
  MigrationsModel := Mock<IDatabaseMigrationsModel>.Create;

  Assert.WillNotRaiseAny(
    procedure
    begin
      Utils.DbMigrations.Run(MigrationsModel, MockUtils.SomeString);
    end);
end;

initialization
  TDUnitX.RegisterTestFixture(TFidoAppUtilsTests);

end.
