unit AuthenticationService.Domain.Entities.User;

interface

uses
  System.SysUtils,
  System.Hash,
  System.RegularExpressions,

  Fido.Exceptions;

type
  EUserValidation = class(EFidoException);

  TUser = record
  private
    FUsername: string;
    FPassword: string;
    FHashedPassword: string;
  public
    constructor Create(const Username: string; const Password: string);

    procedure Validate;

    property Username: string read FUsername;
    property HashedPassword: string read FHashedPassword;
  end;

implementation

{ TUser }

constructor TUser.Create(
  const Username: string;
  const Password: string);
begin
  FUsername := Username;
  FPassword := Password;
  FHashedPassword := THashMD5.GetHashString(FPassword);
end;

procedure TUser.Validate;
begin
  if FUsername.IsEmpty or
     FPassword.IsEmpty then
    raise EUserValidation.Create('Username and password cannot be empty.');

  if not TRegEx.IsMatch(FPassword, '^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$') then
    raise EUserValidation.Create('Password must contain at least minimum eight characters, at least one uppercase letter, one lowercase letter, one number and one special character.');
end;

end.

