SET SCRIPT_DIR=%~dp0

FOR /F "tokens=*" %%g IN ('"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe') do (SET MSBUILD=%%g)

cd %SCRIPT_DIR%\pjproject
"%MSBUILD%" IM7.Static.sln /m /t:Rebuild %2
cd %SCRIPT_DIR%\..

SET DEST=%1\pjproject
ECHO SCRIPT_DIR IS %SCRIPT_DIR%, DEST IS %DEST%, %1
@REM rd /q /s %DEST%
@REM mkdir %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\ImageMagick\config\colors.xml" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\ImageMagick\config\english.xml" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\ImageMagick\config\locale.xml" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\ImageMagick\config\log.xml" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\ImageMagick\config\mime.xml" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\ImageMagick\config\quantization-table.xml" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\Output\bin\configure.xml" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\Output\bin\delegates.xml" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\Output\bin\policy.xml" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\Output\bin\sRGB.icc" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\Output\bin\thresholds.xml" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\Output\bin\type-ghostscript.xml" %DEST%
@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\Output\bin\type.xml" %DEST%

@REM copy "%SCRIPT_DIR%\ImageMagick-Windows\ImageMagick\LICENSE" %DEST%\LICENSE.txt
