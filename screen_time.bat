@echo off
setlocal enabledelayedexpansion

set "prev_batch="

:loop
cls
echo Screen Time Tracker
echo ===================

:: Get current time (HH:MM:SS)
set "curr_time=%time%"
if "%curr_time:~0,1%"==" " set "curr_time=0%curr_time:~1%"

set /a hh=1%curr_time:~0,2%-100
set /a mm=1%curr_time:~3,2%-100
set /a ss=1%curr_time:~6,2%-100

:: Total seconds since midnight
set /a total_sec=hh*3600+mm*60+ss

:: Batch boundaries in seconds
set /a b1_start=9*3600
set /a b1_end=12*3600
set /a b2_end=15*3600
set /a b3_end=18*3600
set /a b4_end=21*3600
set /a day_end=24*3600

:: Determine current batch and remaining time
if %total_sec% lss %b1_start% (
    set "batch=Waiting for Batch 1 (Morning)"
    set /a rem=%b1_start%-%total_sec%
) else if %total_sec% lss %b1_end% (
    set "batch=Batch 1: Morning (9AM-12PM)"
    set /a rem=%b1_end%-%total_sec%
) else if %total_sec% lss %b2_end% (
    set "batch=Batch 2: Afternoon (12PM-3PM)"
    set /a rem=%b2_end%-%total_sec%
) else if %total_sec% lss %b3_end% (
    set "batch=Batch 3: Evening (3PM-6PM)"
    set /a rem=%b3_end%-%total_sec%
) else if %total_sec% lss %b4_end% (
    set "batch=Batch 4: Night (6PM-9PM)"
    set /a rem=%b4_end%-%total_sec%
) else (
    set "batch=Waiting for next day Batch 1 (Morning)"
    set /a rem=%day_end%-%total_sec%+%b1_start%
)

:: Play beep on batch transition
if not "!prev_batch!"=="" if not "!prev_batch!"=="!batch!" (
    powershell -c "[console]::beep(800,400)"
)
set "prev_batch=!batch!"

:: Format remaining time as HH:MM:SS
set /a rh=rem/3600
set /a rmm=(rem%%3600)/60
set /a rs=rem%%60
if %rh% lss 10 set "rh=0%rh%"
if %rmm% lss 10 set "rmm=0%rmm%"
if %rs% lss 10 set "rs=0%rs%"

echo %batch%
echo Remaining: %rh%:%rmm%:%rs%

timeout /t 1 >nul
goto loop