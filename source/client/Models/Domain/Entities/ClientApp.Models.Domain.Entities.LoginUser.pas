unit ClientApp.Models.Domain.Entities.LoginUser;

interface

uses
  System.SysUtils,

  Fido.Exceptions;

type
  ELoginUserValidation = class(EFidoException);

  TLoginUser = record
  private
    FUsername: string;
    FPassword: string;
  public
    property Username: string read FUsername write FUsername;
    property Password: string read FPassword write FPassword;
  end;

implementation

end.
