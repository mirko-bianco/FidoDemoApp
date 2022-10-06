program KVSetter;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IniFiles,
  System.IOUtils,
  Spring,
  Spring.Container,
  Fido.KVStore.Intf,
  FidoApp.Constants,
  KVSetter.DI.Registration in 'KVSetter.DI.Registration.pas';

var
  Container: IShared<TContainer>;
  ConsulKVStore: IKVStore;
  IniFile: IShared<TMemIniFile>;
  Key: IShared<TStringList>;
begin
  try
    Container := Shared.Make(TContainer.Create);
    KVSetter.DI.Registration.DIRegistration(Container);
    IniFile := Shared.Make(TMemIniFile.Create(TPath.Combine(TPath.Combine(ExtractFilePath(Paramstr(0)), 'data'), 'data.ini')));
    ConsulKVStore := Container.Resolve<IKVStore>;
    ConsulKVStore.Put('gateway.address', IniFile.ReadString('KVStore', 'gateway.address', 'http://fabio'), Constants.TIMEOUT).Value;
    ConsulKVStore.Put('gateway.port', IniFile.ReadString('KVStore', 'gateway.port', '9999'), Constants.TIMEOUT).Value;
    ConsulKVStore.Put('redis.host', IniFile.ReadString('KVStore', 'redis.host', 'redis'), Constants.TIMEOUT).Value;
    ConsulKVStore.Put('redis.port', IniFile.ReadString('KVStore', 'redis.port', '6379'), Constants.TIMEOUT).Value;
    ConsulKVStore.Put('database.driverid', IniFile.ReadString('KVStore', 'database.driverid', 'MySQL'), Constants.TIMEOUT).Value;
    ConsulKVStore.Put('database.username', IniFile.ReadString('KVStore', 'database.username', 'root'), Constants.TIMEOUT).Value;
    ConsulKVStore.Put('database.password', IniFile.ReadString('KVStore', 'database.password', 'mysecretpassword'), Constants.TIMEOUT).Value;
    ConsulKVStore.Put('database.server', IniFile.ReadString('KVStore', 'database.server', 'mysql'), Constants.TIMEOUT).Value;
    ConsulKVStore.Put('database.port', IniFile.ReadString('KVStore', 'database.port', '3306'), Constants.TIMEOUT).Value;

    Key := Shared.Make(TStringList.Create);
    Key.LoadFromFile(TPath.Combine(TPath.Combine(ExtractFilePath(Paramstr(0)), 'data'), 'private.key'));
    ConsulKVStore.Put('private.key', Key.Text, Constants.TIMEOUT).Value;
    Key := Shared.Make(TStringList.Create);
    Key.LoadFromFile(TPath.Combine(TPath.Combine(ExtractFilePath(Paramstr(0)), 'data'), 'public.key'));
    ConsulKVStore.Put('public.key', Key.Text, Constants.TIMEOUT).Value;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
