@echo off
REM Claude Relay Service 部署脚本 (Windows 版本)
REM 用于在 Windows 环境下启动和管理服务

setlocal enabledelayedexpansion

REM 设置颜色（Windows 10+）
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "BLUE=[94m"
set "NC=[0m"

REM 获取命令参数
set COMMAND=%1
if "%COMMAND%"=="" set COMMAND=start

REM 主逻辑
if /i "%COMMAND%"=="start" goto start_service
if /i "%COMMAND%"=="stop" goto stop_service
if /i "%COMMAND%"=="restart" goto restart_service
if /i "%COMMAND%"=="status" goto show_status
if /i "%COMMAND%"=="logs" goto show_logs
if /i "%COMMAND%"=="clean" goto clean_restart
if /i "%COMMAND%"=="help" goto show_help
if /i "%COMMAND%"=="--help" goto show_help
if /i "%COMMAND%"=="-h" goto show_help

echo %RED%未知命令: %COMMAND%%NC%
echo.
goto show_help

:show_help
echo Claude Relay Service 部署管理脚本 (Windows)
echo.
echo 用法: deploy.bat [命令]
echo.
echo 命令:
echo   start      启动服务 (默认)
echo   stop       停止服务
echo   restart    重启服务
echo   status     查看服务状态
echo   logs       查看服务日志
echo   clean      清理并重启服务
echo   help       显示此帮助信息
echo.
goto end

:check_requirements
REM 检查 Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo %RED%错误: Docker 未安装%NC%
    exit /b 1
)

REM 检查 Docker 服务
docker info >nul 2>&1
if errorlevel 1 (
    echo %RED%错误: Docker 服务未运行%NC%
    exit /b 1
)

REM 检查 docker-compose
docker compose version >nul 2>&1
if errorlevel 1 (
    docker-compose --version >nul 2>&1
    if errorlevel 1 (
        echo %RED%错误: docker-compose 未安装%NC%
        exit /b 1
    )
    set DOCKER_COMPOSE=docker-compose
) else (
    set DOCKER_COMPOSE=docker compose
)
exit /b 0

:check_env
if not exist ".env" (
    echo %YELLOW%警告: 未找到 .env 文件%NC%
    echo.
    set /p REPLY="是否运行 init-env.bat 初始化环境? (Y/n): "
    if /i not "!REPLY!"=="n" (
        if exist "init-env.bat" (
            call init-env.bat
        ) else (
            echo %RED%错误: 找不到 init-env.bat 脚本%NC%
            exit /b 1
        )
    ) else (
        echo %RED%错误: 需要 .env 文件才能启动服务%NC%
        exit /b 1
    )
)
exit /b 0

:start_service
echo %GREEN%======================================%NC%
echo %GREEN%启动 Claude Relay Service%NC%
echo %GREEN%======================================%NC%
echo.

call :check_requirements
if errorlevel 1 exit /b 1

call :check_env
if errorlevel 1 exit /b 1

echo %YELLOW%正在启动服务...%NC%
%DOCKER_COMPOSE% up -d

if errorlevel 1 (
    echo %RED%服务启动失败%NC%
    exit /b 1
)

echo.
echo %GREEN%服务启动成功！%NC%
echo.
timeout /t 3 >nul
call :show_status
call :show_access_info
goto end

:stop_service
echo %YELLOW%正在停止服务...%NC%
call :check_requirements
if errorlevel 1 exit /b 1

%DOCKER_COMPOSE% down

if errorlevel 1 (
    echo %RED%停止服务失败%NC%
    exit /b 1
)

echo %GREEN%服务已停止%NC%
goto end

:restart_service
echo %YELLOW%正在重启服务...%NC%
call :check_requirements
if errorlevel 1 exit /b 1

%DOCKER_COMPOSE% restart

if errorlevel 1 (
    echo %RED%重启服务失败%NC%
    exit /b 1
)

echo %GREEN%服务已重启%NC%
timeout /t 3 >nul
call :show_status
goto end

:show_status
echo %BLUE%======================================%NC%
echo %BLUE%服务状态%NC%
echo %BLUE%======================================%NC%
call :check_requirements
if errorlevel 1 exit /b 1

%DOCKER_COMPOSE% ps
goto end

:show_logs
echo %BLUE%服务日志 (按 Ctrl+C 退出)%NC%
echo.
call :check_requirements
if errorlevel 1 exit /b 1

%DOCKER_COMPOSE% logs -f
goto end

:clean_restart
echo %YELLOW%清理并重启服务...%NC%
echo %RED%警告: 这将删除所有容器并重新创建%NC%
set /p REPLY="确认继续? (y/N): "
if /i "!REPLY!"=="y" (
    call :check_requirements
    if errorlevel 1 exit /b 1

    %DOCKER_COMPOSE% down -v
    %DOCKER_COMPOSE% up -d
    echo %GREEN%服务已清理并重启%NC%
    timeout /t 3 >nul
    call :show_status
) else (
    echo 已取消操作
)
goto end

:show_access_info
REM 读取端口配置
set PORT=3000
for /f "tokens=2 delims==" %%a in ('findstr "^PORT=" .env 2^>nul') do set PORT=%%a

REM 获取本机 IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set LOCAL_IP=%%a
    set LOCAL_IP=!LOCAL_IP: =!
    goto :got_ip
)
:got_ip
if "!LOCAL_IP!"=="" set LOCAL_IP=127.0.0.1

echo.
echo %BLUE%======================================%NC%
echo %BLUE%访问信息%NC%
echo %BLUE%======================================%NC%
echo.
echo 管理界面访问地址:
echo   本地: http://localhost:%PORT%/web
echo   局域网: http://!LOCAL_IP!:%PORT%/web
echo.
echo API 端点:
echo   Claude API: http://!LOCAL_IP!:%PORT%/api
echo   健康检查: http://!LOCAL_IP!:%PORT%/health
echo.
echo 首次登录:
echo   管理员凭据保存在: .\data\app\init.json
echo   查看凭据: type .\data\app\init.json
echo.
echo 日志文件:
echo   应用日志: .\data\logs\
echo   Redis 数据: .\data\redis\
echo.
exit /b 0

:end
endlocal
