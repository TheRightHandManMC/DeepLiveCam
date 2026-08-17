@echo off
if exist "%~dp0venv\Scripts\python.exe" (
    "%~dp0venv\Scripts\python.exe" "%~dp0run.py" --execution-provider openvino %*
) else (
    python "%~dp0run.py" --execution-provider openvino %*
)
