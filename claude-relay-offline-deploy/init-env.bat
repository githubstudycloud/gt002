@echo off
REM 环境初始化脚本 (Windows 版本)
REM 生成密钥和初始化环境配置

setlocal enabledelayedexpansion

REM 设置颜色
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "BLUE=[94m"
set "NC=[0m"

echo %GREEN%======================================%NC%
echo %GREEN%Claude Relay Service 环境初始化%NC%
echo %GREEN%======================================%NC%
echo.

set ENV_FILE=.env

REM 检查 .env 文件是否存在
if exist "%ENV_FILE%" (
    echo %YELLOW%检测到现有 .env 文件%NC%
    set /p REPLY="是否覆盖现有配置? (y/N): "
    if /i not "!REPLY!"=="y" (
        echo 已取消操作
        exit /b 0
    )

    REM 备份现有配置
    for /f "tokens=1-3 delims=/: " %%a in ("%date% %time%") do (
        set TIMESTAMP=%%a%%b%%c_%%d%%e%%f
    )
    move "%ENV_FILE%" "%ENV_FILE%.backup.!TIMESTAMP!"
    echo %GREEN%已备份原配置文件%NC%
)

echo %YELLOW%步骤 1/3: 生成安全密钥...%NC%

REM 生成随机密钥（使用 PowerShell）
for /f "delims=" %%i in ('powershell -Command "[guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')"') do set JWT_SECRET=%%i
echo %GREEN%JWT_SECRET 已生成%NC%

for /f "delims=" %%i in ('powershell -Command "[guid]::NewGuid().ToString('N').Substring(0, 32)"') do set ENCRYPTION_KEY=%%i
echo %GREEN%ENCRYPTION_KEY 已生成%NC%

for /f "delims=" %%i in ('powershell -Command "[guid]::NewGuid().ToString('N').Substring(0, 24)"') do set REDIS_PASSWORD=%%i
echo %GREEN%REDIS_PASSWORD 已生成%NC%

echo.
echo %YELLOW%步骤 2/3: 创建 .env 配置文件...%NC%

REM 复制 .env.example
if not exist ".env.example" (
    echo %RED%错误: 找不到 .env.example 文件%NC%
    exit /b 1
)

copy .env.example "%ENV_FILE%" >nul

REM 替换密钥（使用 PowerShell）
powershell -Command "(gc %ENV_FILE%) -replace 'JWT_SECRET=', 'JWT_SECRET=%JWT_SECRET%' | Out-File -encoding ASCII %ENV_FILE%"
powershell -Command "(gc %ENV_FILE%) -replace 'ENCRYPTION_KEY=', 'ENCRYPTION_KEY=%ENCRYPTION_KEY%' | Out-File -encoding ASCII %ENV_FILE%"
powershell -Command "(gc %ENV_FILE%) -replace 'REDIS_PASSWORD=', 'REDIS_PASSWORD=%REDIS_PASSWORD%' | Out-File -encoding ASCII %ENV_FILE%"

echo %GREEN%.env 文件已创建%NC%

echo.
echo %YELLOW%步骤 3/3: 创建数据目录...%NC%

if not exist "data" mkdir data
if not exist "data\logs" mkdir data\logs
if not exist "data\app" mkdir data\app
if not exist "data\redis" mkdir data\redis

echo %GREEN%数据目录已创建%NC%

echo.
echo %GREEN%======================================%NC%
echo %GREEN%初始化完成！%NC%
echo %GREEN%======================================%NC%
echo.
echo 生成的密钥信息:
echo   JWT_SECRET: %JWT_SECRET:~0,10%... (已保存到 .env)
echo   ENCRYPTION_KEY: %ENCRYPTION_KEY:~0,10%... (已保存到 .env)
echo   REDIS_PASSWORD: %REDIS_PASSWORD:~0,10%... (已保存到 .env)
echo.
echo %YELLOW%重要提示:%NC%
echo   1. 请妥善保管 .env 文件，不要提交到 Git
echo   2. 如果重新生成密钥，将无法访问旧的 Redis 数据
echo   3. 可以手动编辑 .env 文件自定义其他配置
echo.
echo 下一步操作:
echo   运行 deploy.bat start 启动服务
echo.

endlocal
