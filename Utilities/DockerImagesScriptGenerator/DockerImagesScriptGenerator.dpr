program DockerImagesScriptGenerator;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.Classes,
  System.SysUtils,
  System.IOUtils,
  Spring;

begin
  try
    var StringList: IShared<TStringList> := Shared.Make(TStringList.Create);
    for var Path in TDirectory.GetDirectories(ParamStr(1)) do
      if Length(TDirectory.GetFiles(Path, 'DockerFile')) = 1 then
        StringList.Add(Format('docker build . -f %s\Dockerfile -t mirkobianco/%s:latest', [Path, LowerCase(ExtractFileName(Path))]));

    StringList.SaveToFile(ParamStr(2));
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
