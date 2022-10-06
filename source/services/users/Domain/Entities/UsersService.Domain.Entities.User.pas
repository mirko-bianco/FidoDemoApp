unit UsersService.Domain.Entities.User;

interface

uses
  System.SysUtils,

  Fido.Exceptions;

type
  EUserValidation = class(EFidoException);

  TUser = record
  private
    FId: TGuid;
    FFirstName: string;
    FLastName: string;
    FActive: Boolean;
  public
    class operator Initialize(out Dest: TUser);

    procedure Validate;

    function Id: TGuid;
    procedure SetId(const Id: TGuid);
    function FirstName: string;
    procedure SetFirstName(const FirstName: string);
    function LastName: string;
    procedure SetLastName(const LastName: string);
    function Active: Boolean;
    procedure SetActive(const Active: Boolean);
  end;

implementation

{ TUser }

function TUser.Active: Boolean;
begin
  Result := FActive;
end;

function TUser.FirstName: string;
begin
  Result := FFirstName;
end;

function TUser.Id: TGuid;
begin
  Result := FId;
end;

class operator TUser.Initialize(out Dest: TUser);
begin
  Dest.SetActive(True);
end;

function TUser.LastName: string;
begin
  Result := FLastName;
end;

procedure TUser.SetActive(const Active: Boolean);
begin
  FActive := Active;
end;

procedure TUser.SetFirstName(const FirstName: string);
begin
  FFirstName := FirstName;
end;

procedure TUser.SetId(const Id: TGuid);
begin
  FId := Id;
end;

procedure TUser.SetLastName(const LastName: string);
begin
  FLastName := LastName;
end;

procedure TUser.Validate;
begin
  if FId.IsEmpty then
    raise EUserValidation.Create('Id cannot be empty.');

  if FFirstName.IsEmpty then
    raise EUserValidation.Create('First name cannot be empty.');

  if FLastName.IsEmpty then
    raise EUserValidation.Create('Last name cannot be empty.');
end;

end.
