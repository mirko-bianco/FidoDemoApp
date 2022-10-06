unit KVSetter.DI.Registration;

interface

uses
  System.IniFiles,

  Spring,
  Spring.Container,

  Fido.KVStore.Intf,
  Fido.Consul.DI.Registration,

  FidoApp.Utils;

procedure DIRegistration(const Container: TContainer);

implementation

procedure DIRegistration(const Container: TContainer);
var
  IniFile: IShared<TMemIniFile>;
begin
  IniFile := Shared.Make(TMemIniFile.Create(Utils.Files.GetIniFilename));
  Fido.Consul.DI.Registration.Register(Container, IniFile);
  Container.Build;
end;

end.
