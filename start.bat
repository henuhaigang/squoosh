@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

set "PORT=3000"
set "DIR=%~dp0"
set "PID_FILE=%DIR%.squoosh.pid"

if not "%1"=="" (
    if "%1"=="stop" goto :stop
    if "%1"=="restart" goto :restart
    if "%1"=="status" goto :status
    if "%1"=="start" (
        if not "%2"=="" set "PORT=%2"
        goto :start
    )
    REM 第一个参数是数字则当作端口
    set /a "TEST_PORT=%1" 2>nul
    if !TEST_PORT! gtr 0 set "PORT=%1"
    goto :start
)

:start
call :check_node
call :install_deps
call :build
call :stop_internal

echo [INFO] 启动服务，端口: %PORT%
start /b cmd /c "npx serve "%DIR%build" -l %PORT% > "%DIR%.squoosh.log" 2>&1"
timeout /t 3 /nobreak >nul

for /f "tokens=*" %%i in ('type "%DIR%.squoosh.log"') do echo    %%i

echo.
echo [INFO] 服务启动成功!
echo    本机访问: http://localhost:%PORT%
echo    停止服务: start.bat stop
echo.
goto :eof

:stop
call :stop_internal
echo [INFO] 服务已停止
goto :eof

:stop_internal
taskkill /f /im node.exe /fi "WINDOWTITLE eq serve*" >nul 2>&1
goto :eof

:restart
if not "%2"=="" set "PORT=%2"
goto :start

:status
tasklist /fi "imagename eq node.exe" 2>nul | find /i "node.exe" >nul
if %errorlevel%==0 (
    echo [INFO] 服务可能正在运行
) else (
    echo [WARN] 服务未运行
)
goto :eof

:check_node
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 未找到 Node.js，请先安装 Node.js ^>= 20.x
    echo    下载地址: https://nodejs.org
    exit /b 1
)
for /f "tokens=*" %%v in ('node -v') do echo [INFO] Node.js 版本: %%v
goto :eof

:install_deps
if not exist "%DIR%node_modules" (
    echo [INFO] 首次运行，正在安装依赖...
    cd /d "%DIR%" && npm ci --silent
    echo [INFO] 依赖安装完成
)
goto :eof

:build
if not exist "%DIR%build\index.html" (
    echo [INFO] 正在构建项目...
    cd /d "%DIR%" && npm run build
    echo [INFO] 构建完成
)
goto :eof
