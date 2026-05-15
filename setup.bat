@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

REM ============================================================
REM  Unity 프로젝트 템플릿 셋업 스크립트
REM  - Assets/Scripts/ 안에서 실행
REM  - 설정 파일들을 프로젝트 루트로 이동
REM  - 템플릿 .git 히스토리 제거
REM  - 자기 자신 삭제
REM ============================================================

echo.
echo ===============================================
echo  Unity Project Template Setup
echo ===============================================
echo.

REM 현재 위치 확인 (Assets/Scripts 안에 있어야 함)
set "SCRIPTS_DIR=%~dp0"
set "SCRIPTS_DIR=%SCRIPTS_DIR:~0,-1%"

REM Assets/Scripts 형태인지 검증
for %%I in ("%SCRIPTS_DIR%") do set "CURRENT_FOLDER=%%~nxI"
for %%I in ("%SCRIPTS_DIR%\..") do set "PARENT_FOLDER=%%~nxI"

if /I not "%CURRENT_FOLDER%"=="Scripts" (
    echo [ERROR] 이 스크립트는 Assets\Scripts\ 폴더 안에서 실행되어야 합니다.
    echo         현재 위치: %SCRIPTS_DIR%
    pause
    exit /b 1
)

if /I not "%PARENT_FOLDER%"=="Assets" (
    echo [ERROR] 부모 폴더가 Assets\가 아닙니다.
    echo         현재 위치: %SCRIPTS_DIR%
    pause
    exit /b 1
)

REM 프로젝트 루트 = Assets의 부모
set "PROJECT_ROOT=%SCRIPTS_DIR%\..\.."
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%CD%"
popd

REM ProjectSettings 폴더가 있는지로 Unity 프로젝트인지 검증
if not exist "%PROJECT_ROOT%\ProjectSettings" (
    echo [ERROR] 프로젝트 루트에 ProjectSettings 폴더가 없습니다.
    echo         Unity 프로젝트가 맞는지 확인하세요.
    echo         프로젝트 루트: %PROJECT_ROOT%
    pause
    exit /b 1
)

echo [INFO] Scripts 폴더: %SCRIPTS_DIR%
echo [INFO] 프로젝트 루트: %PROJECT_ROOT%
echo.

REM ============================================================
REM  1. 템플릿 .git 폴더 제거
REM ============================================================
echo [1/4] 템플릿 Git 히스토리 제거 중...
if exist "%SCRIPTS_DIR%\.git" (
    rmdir /S /Q "%SCRIPTS_DIR%\.git"
    echo       .git 폴더 삭제 완료
) else (
    echo       .git 폴더 없음 ^(건너뜀^)
)
echo.

REM ============================================================
REM  2. 설정 파일들을 프로젝트 루트로 이동
REM ============================================================
echo [2/4] 설정 파일을 프로젝트 루트로 이동 중...

call :move_to_root ".editorconfig"
call :move_to_root ".gitignore"
call :delete_file ".gitattributes"
call :delete_file "README.md"
echo.

REM ============================================================
REM  3. Unity가 만든 .meta 파일들 정리
REM ============================================================
echo [3/4] 불필요한 .meta 파일 정리 중...

REM 설정 파일들의 .meta가 생겼다면 삭제
call :delete_meta "%SCRIPTS_DIR%\.editorconfig.meta"
call :delete_meta "%SCRIPTS_DIR%\.gitignore.meta"
call :delete_meta "%SCRIPTS_DIR%\.gitattributes.meta"
call :delete_meta "%SCRIPTS_DIR%\README.md.meta"
echo.

REM ============================================================
REM  4. setup.bat 자기 자신 삭제 + .meta 삭제
REM ============================================================
echo [4/4] 셋업 스크립트 자체 삭제 중...
call :delete_meta "%SCRIPTS_DIR%\setup.bat.meta"

echo.
echo ===============================================
echo  셋업 완료!
echo ===============================================
echo.
echo 다음 단계:
echo   1. Unity Editor를 열어서 프로젝트 로드
echo   2. (선택) 새 Git 레포 초기화: git init
echo.
pause

REM 자기 자신 삭제 (트릭: 현재 실행 중인 .bat을 지우려면 시간차 필요)
(goto) 2>nul & del "%~f0"
exit /b 0

REM ============================================================
REM  서브루틴
REM ============================================================

:move_to_root
    set "FILE_NAME=%~1"
    if exist "%SCRIPTS_DIR%\%FILE_NAME%" (
        if exist "%PROJECT_ROOT%\%FILE_NAME%" (
            echo       [SKIP] %FILE_NAME% - 프로젝트 루트에 이미 존재
        ) else (
            move /Y "%SCRIPTS_DIR%\%FILE_NAME%" "%PROJECT_ROOT%\%FILE_NAME%" > nul
            echo       [MOVE] %FILE_NAME% → 프로젝트 루트
        )
    ) else (
        echo       [SKIP] %FILE_NAME% - 원본 없음
    )
exit /b 0

:delete_file
    set "FILE_NAME=%~1"
    if exist "%SCRIPTS_DIR%\%FILE_NAME%" (
        del /Q "%SCRIPTS_DIR%\%FILE_NAME%"
        echo       [DEL]  %FILE_NAME%
    ) else (
        echo       [SKIP] %FILE_NAME% - 원본 없음
    )
exit /b 0

:delete_meta
    set "META_PATH=%~1"
    if exist "%META_PATH%" (
        del /Q "%META_PATH%"
        for %%I in ("%META_PATH%") do echo       삭제: %%~nxI
    )
exit /b 0
