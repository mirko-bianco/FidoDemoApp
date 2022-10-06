unit AuthorizationService.Domain.UseCases.ConvertToJWT;

interface

uses
  System.SysUtils,

  JOSE.Core.JWT,

  Spring,

  Fido.JWT.Manager.Intf,
  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Functional.Ifs,

  FidoApp.Constants,

  AuthorizationService.Domain.UseCases.ConvertToJWT.Intf;

type
  TConvertToJWTUseCase = class(TInterfacedObject, IConvertToJWTUseCase)
  private
    FJWTManager: IJWTManager;
    FValidationKey: string;

    function CheckUserId(const Token: TJWT): Context<TJWT>;
    function DoValidateUserId(const Token: TJWT): TJWT;
    function DoVerifyToken(const Authorization: string): TJWT;
    function DoCheckToken(const Token: TJWT): Boolean;
    function DoIsAssigned(const Token: TJWT): TJWT;
    function DoIsNotAssigned(const Token: TJWT): TJWT;
  public
    constructor Create(const JWTManager: IJWTManager; const ValidationKey: string);

    function Run(const Authorization: string): Context<TJWT>;
  end;

implementation

{ TConvertToJWTUseCase }

constructor TConvertToJWTUseCase.Create(
  const JWTManager: IJWTManager;
  const ValidationKey: string);
begin
  inherited Create;

  FJWTManager := Utilities.CheckNotNullAndSet(JWTManager, 'JWTManager');
  FValidationKey := ValidationKey;
end;

function TConvertToJWTUseCase.DoValidateUserId(const Token: TJWT): TJWT;
begin
  Result := Token;
  TGuid.Create(Result.Claims.JSON.GetValue(Constants.CLAIM_USERID).Value.DeQuotedString('"'));
end;

function TConvertToJWTUseCase.CheckUserId(const Token: TJWT): Context<TJWT>;
begin
  Result := &Try<TJWT>.New(Token).Map<TJWT>(DoValidateUserId).Match(EConvertToJWTUseCaseValidation, 'Authentication is not correct');
end;

function TConvertToJWTUseCase.DoCheckToken(const Token: TJWT): Boolean;
begin
  Result := Assigned(Token);
end;

function TConvertToJWTUseCase.DoIsAssigned(const Token: TJWT): TJWT;
begin
  Result := Token;
end;

function TConvertToJWTUseCase.DoIsNotAssigned(const Token: TJWT): TJWT;
begin
  raise EConvertToJWTUseCaseValidation.Create('Authentication is not correct')
end;

function TConvertToJWTUseCase.DoVerifyToken(const Authorization: string): TJWT;
begin
  Result := FJWTManager.VerifyToken(Authorization.Replace('Bearer ', ''), FValidationKey);
end;

function TConvertToJWTUseCase.Run(const Authorization: string): Context<TJWT>;
begin
  Result := &If<TJwt>.
    New(Context<string>.
      New(Authorization).
      Map<TJwt>(DoVerifyToken)).
    Map(DoCheckToken).
    &Then<TJwt>(DoIsAssigned, DoIsNotAssigned).
    Map<TJwt>(CheckUserId);
end;

end.
