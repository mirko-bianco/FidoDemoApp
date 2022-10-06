unit ClientApp.Models.Domain.Entities.SignupUser;

interface

uses
  System.SysUtils,

  Fido.Exceptions;

type
  ESignupUserValidation = class(EFidoException);

  TSignupUser = record
  private
    FUsername: string;
    FPassword: string;
    FRepeatedPassword: string;
    FFirstName: string;
    FLastName: string;
  public
    procedure Validate;

    property Username: string read FUsername write FUsername;
    property Password: string read FPassword write FPassword;
    property RepeatedPassword: string read FRepeatedPassword write FRepeatedPassword;
    property FirstName: string read FFirstName write FFirstName;
    property LastName: string read FLastName write FLastName;
  end;

implementation

{ TSignupUser }

procedure TSignupUser.Validate;
begin
  if not FPassword.Equals(FRepeatedPassword) then
    raise ESignupUserValidation.Create('Password and repeated password are not the same.');
end;

end.
