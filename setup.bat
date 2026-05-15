@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

REM ============================================================
REM  Unity 프로젝트 템플릿 셋업 스크립트
REM  - Assets/UnityProjectSetting/ 안에서 실행
REM  - Scripts/, Tests/ 폴더를 Assets/ 바로 아래로 이동
REM  - .editorconfig, .gitignore를 프로젝트 루트로 이동
REM  - 나머지(.gitattributes, README.md, .git) 삭제
REM  - 자기 자신과 UnityProjectSetting 폴더까지 삭제
REM ============================================================

echo.
echo ===============================================
echo  Unity Project Template Setup
echo ===============================================
echo.

REM ============================================================
REM  경로 계산
REM ============================================================
REM SETUP_DIR     = Assets/UnityProjectSetting/  (이 .bat 위치)
REM ASSETS_DIR    = Assets/
REM PROJECT_ROOT  = Unity 프로젝트 루트
REM ============================================================

set "SETUP_DIR=%~dp0"
set "SETUP_DIR=%SETUP_DIR:~0,-1%"

REM 폴더 이름 검증
for %%I in ("%SETUP_DIR%") do set "CURRENT_FOLDER=%%~nxI"
for %%I in ("%SETUP_DIR%\..") do set "PARENT_FOLDER=%%~nxI"

if /I not "%CURRENT_FOLDER%"=="UnityProjectSetting" (
    echo [ERROR] 이 스크립트는 Assets\UnityProjectSetting\ 폴더 안에서 실행되어야 합니다.
    echo         현재 위치: %SETUP_DIR%
    pause
    exit /b 1
)

if /I not "%PARENT_FOLDER%"=="Assets" (
    echo [ERROR] 부모 폴더가 Assets\가 아닙니다.
    echo         현재 위치: %SETUP_DIR%
    pause
    exit /b 1
)

REM Assets 폴더 절대 경로
pushd "%SETUP_DIR%\.."
set "ASSETS_DIR=%CD%"
popd

REM 프로젝트 루트 절대 경로
pushd "%ASSETS_DIR%\.."
set "PROJECT_ROOT=%CD%"
popd

REM ProjectSettings 존재 여부로 Unity 프로젝트인지 검증
if not exist "%PROJECT_ROOT%\ProjectSettings" (
    echo [ERROR] 프로젝트 루트에 ProjectSettings 폴더가 없습니다.
    echo         Unity 프로젝트가 맞는지 확인하세요.
    echo         프로젝트 루트: %PROJECT_ROOT%
    pause
    exit /b 1
)

echo [INFO] 셋업 폴더:     %SETUP_DIR%
echo [INFO] Assets:        %ASSETS_DIR%
echo [INFO] 프로젝트 루트: %PROJECT_ROOT%
echo.

REM ============================================================
REM  1. 템플릿 .git 폴더 제거
REM ============================================================
echo [1/6] 템플릿 Git 히스토리 제거 중...
if exist "%SETUP_DIR%\.git" (
    rmdir /S /Q "%SETUP_DIR%\.git"
    echo       .git 폴더 삭제 완료
) else (
    echo       .git 폴더 없음 ^(건너뜀^)
)
echo.

REM ============================================================
REM  2. Scripts, Tests 폴더를 Assets/로 이동
REM ============================================================
echo [2/6] 폴더를 Assets/로 이동 중...

call :move_folder_to_assets "Scripts"
call :move_folder_to_assets "Tests"
echo.

REM ============================================================
REM  3. 설정 파일을 프로젝트 루트로 이동
REM ============================================================
echo [3/6] 설정 파일을 프로젝트 루트로 이동 중...

call :move_to_root ".editorconfig"
call :move_to_root ".gitignore"
echo.

REM ============================================================
REM  4. 불필요 파일 삭제
REM ============================================================
echo [4/6] 불필요 파일 삭제 중...

call :delete_file ".gitattributes"
call :delete_file "README.md"
echo.

REM ============================================================
REM  5. Unity가 만든 .meta 파일 정리
REM ============================================================
echo [5/6] 불필요한 .meta 파일 정리 중...

call :delete_meta "%SETUP_DIR%\.editorconfig.meta"
call :delete_meta "%SETUP_DIR%\.gitignore.meta"
call :delete_meta "%SETUP_DIR%\.gitattributes.meta"
call :delete_meta "%SETUP_DIR%\README.md.meta"
call :delete_meta "%SETUP_DIR%\setup.bat.meta"

REM Assets/UnityProjectSetting.meta 도 삭제 (폴더 자체가 사라지니까)
call :delete_meta "%ASSETS_DIR%\UnityProjectSetting.meta"
echo.

REM ============================================================
REM  6. 셋업 스크립트와 UnityProjectSetting 폴더 삭제
REM ============================================================
echo [6/6] 셋업 폴더 자체 정리 중...

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

REM 자기 자신 + UnityProjectSetting 폴더 통째로 삭제
REM 트릭: 임시 .bat을 생성해서 시간차로 부모 폴더까지 정리
(
    echo @echo off
    echo timeout /t 1 /nobreak ^> nul
    echo rmdir /S /Q "%SETUP_DIR%"
    echo del "%%~f0"
) > "%TEMP%\unity_template_cleanup.bat"

start "" /B "%TEMP%\unity_template_cleanup.bat"
exit /b 0

REM ============================================================
REM  서브루틴
REM ============================================================

:move_folder_to_assets
    set "FOLDER_NAME=%~1"
    if exist "%SETUP_DIR%\%FOLDER_NAME%" (
        if exist "%ASSETS_DIR%\%FOLDER_NAME%" (
            echo       [SKIP] %FOLDER_NAME%\ - Assets\에 이미 존재
        ) else (
            move "%SETUP_DIR%\%FOLDER_NAME%" "%ASSETS_DIR%\%FOLDER_NAME%" > nul
            echo       [MOVE] %FOLDER_NAME%\ → Assets\
        )
    ) else (
        echo       [SKIP] %FOLDER_NAME%\ - 원본 없음
    )
exit /b 0

:move_to_root
    set "FILE_NAME=%~1"
    if exist "%SETUP_DIR%\%FILE_NAME%" (
        if exist "%PROJECT_ROOT%\%FILE_NAME%" (
            echo       [SKIP] %FILE_NAME% - 프로젝트 루트에 이미 존재
        ) else (
            move /Y "%SETUP_DIR%\%FILE_NAME%" "%PROJECT_ROOT%\%FILE_NAME%" > nul
            echo       [MOVE] %FILE_NAME% → 프로젝트 루트
        )
    ) else (
        echo       [SKIP] %FILE_NAME% - 원본 없음
    )
exit /b 0

:delete_file
    set "FILE_NAME=%~1"
    if exist "%SETUP_DIR%\%FILE_NAME%" (
        del /Q "%SETUP_DIR%\%FILE_NAME%"
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