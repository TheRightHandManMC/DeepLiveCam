@echo off
setlocal enabledelayedexpansion

rem One-click Windows setup for the OpenVINO(TM) execution provider (Intel CPU/GPU/NPU).
rem Creates a virtual environment, installs the dependencies, pairs
rem onnxruntime-openvino with the matching openvino runtime and fetches the models.

set "ORT_OPENVINO_VERSION=1.24.1"
set "OPENVINO_VERSION=2025.4.1"
set "ROOT=%~dp0"
cd /d "%ROOT%"

echo ============================================
echo  Deep-Live-Cam - OpenVINO setup for Windows
echo ============================================
echo.

rem ---------------------------------------------------------------- python ---
set "PYTHON="
for %%V in (3.14 3.13 3.12 3.11) do (
    if not defined PYTHON (
        py -%%V -c "import sys" >nul 2>&1 && set "PYTHON=py -%%V"
    )
)
if not defined PYTHON (
    python -c "import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)" >nul 2>&1 && set "PYTHON=python"
)
if not defined PYTHON (
    echo [ERROR] Python 3.11 or newer was not found.
    echo         Install it from https://www.python.org/downloads/windows/
    echo         and make sure "Add python.exe to PATH" is checked.
    goto :fail
)
echo [1/5] Using interpreter: %PYTHON%

rem ------------------------------------------------------------------ venv ---
if exist "venv\Scripts\python.exe" (
    echo [2/5] Reusing existing virtual environment in "venv".
) else (
    echo [2/5] Creating virtual environment in "venv"...
    %PYTHON% -m venv venv || goto :fail
)
set "VENV_PY=%ROOT%venv\Scripts\python.exe"

rem ------------------------------------------------------------ dependencies ---
echo [3/5] Installing dependencies (this can take several minutes)...
"%VENV_PY%" -m pip install --upgrade pip || goto :fail
"%VENV_PY%" -m pip install -r requirements.txt || goto :fail

echo       Switching onnxruntime to the OpenVINO build...
"%VENV_PY%" -m pip uninstall -y onnxruntime onnxruntime-gpu onnxruntime-directml onnxruntime-openvino >nul 2>&1
"%VENV_PY%" -m pip install "openvino==%OPENVINO_VERSION%" || goto :fail
"%VENV_PY%" -m pip install "onnxruntime-openvino==%ORT_OPENVINO_VERSION%" || goto :fail

rem ---------------------------------------------------------------- models ---
echo [4/5] Downloading models...
if not exist "models" mkdir "models"
call :download GFPGANv1.4.onnx
if errorlevel 1 goto :fail
call :download inswapper_128_fp16.onnx
if errorlevel 1 goto :fail

rem ----------------------------------------------------------------- check ---
echo [5/5] Verifying the OpenVINO execution provider...
"%VENV_PY%" -c "import onnxruntime; ps = onnxruntime.get_available_providers(); print('   providers:', ', '.join(ps)); raise SystemExit(0 if 'OpenVINOExecutionProvider' in ps else 1)"
if errorlevel 1 (
    echo [ERROR] OpenVINOExecutionProvider is not available in this environment.
    goto :fail
)

echo.
echo Setup complete. Start Deep-Live-Cam with run-openvino.bat
echo.
choice /c YN /m "Launch Deep-Live-Cam now"
if errorlevel 2 goto :done
call "%ROOT%run-openvino.bat"
goto :done

rem --------------------------------------------------------------- helpers ---
:download
if exist "models\%~1" (
    echo       %~1 already present, skipping.
    exit /b 0
)
echo       Downloading %~1...
curl -L --fail --progress-bar -o "models\%~1" "https://huggingface.co/hacksider/deep-live-cam/resolve/main/%~1"
if errorlevel 1 (
    if exist "models\%~1" del "models\%~1"
    echo [ERROR] Failed to download %~1.
    exit /b 1
)
exit /b 0

:fail
echo.
echo Setup failed. Scroll up for the first error message.
endlocal
pause
exit /b 1

:done
endlocal
pause
exit /b 0
