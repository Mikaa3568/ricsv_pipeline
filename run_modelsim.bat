@echo off
title Chay Mo Phong ModelSim - RISC-V Pipeline
cd /d "%~dp0"

echo ===================================================================
echo   DANG KHOI DONG MODELSIM CHO BO XU LY RISC-V 5-STAGE PIPELINE...
echo ===================================================================

:: Kiem tra lenh vsim trong he thong
where vsim >nul 2>nul
if %errorlevel%==0 (
    start "" vsim -gui -do "do run_sim.do"
    exit /b
)

:: Kiem tra duong dan mac dinh Altera 13.0sp1
if exist "C:\altera\13.0sp1\modelsim_ase\win32aloem\vsim.exe" (
    start "" "C:\altera\13.0sp1\modelsim_ase\win32aloem\vsim.exe" -gui -do "do run_sim.do"
    exit /b
)

:: Kiem tra duong dan Altera
if exist "C:\altera\modelsim_ase\win32aloem\vsim.exe" (
    start "" "C:\altera\modelsim_ase\win32aloem\vsim.exe" -gui -do "do run_sim.do"
    exit /b
)

echo [LOI] Khong tim thay ModelSim (vsim.exe)!
pause

