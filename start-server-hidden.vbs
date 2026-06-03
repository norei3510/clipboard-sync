Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
serverBat = fso.BuildPath(scriptDir, "start-server.bat")
logsDir = fso.BuildPath(scriptDir, "logs")
logFile = fso.BuildPath(logsDir, "server.log")

If Not fso.FolderExists(logsDir) Then
    fso.CreateFolder(logsDir)
End If

command = "%ComSpec% /c " & Chr(34) & Chr(34) & serverBat & Chr(34) & " >> " & Chr(34) & logFile & Chr(34) & " 2>&1" & Chr(34)
shell.Run command, 0, False
