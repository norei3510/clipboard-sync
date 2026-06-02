Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
serverBat = fso.BuildPath(scriptDir, "start-server.bat")

shell.Run Chr(34) & serverBat & Chr(34), 0, False
