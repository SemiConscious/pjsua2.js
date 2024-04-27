SET SCRIPT_DIR=%~dp0

cd %SCRIPT_DIR%
(rd /q /s pjproject) ^& if %ERRORLEVEL% leq 1 set ERRORLEVEL = 0
cd pjproject
call CloneRepositories.IM7.cmd

cd deps\pjproject\Configure
FOR /F "tokens=*" %%g IN ('"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe') do (SET MSBUILD=%%g)

"%MSBUILD%" Configure.sln /m /t:Rebuild /p:Configuration=Release,Platform=x64
Configure.exe /noWizard /VS2022 /HDRI /Q16 /x64 /smt

exit /b 0
