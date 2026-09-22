# Screen Time Tracker - Implementation Plan

## Overview
A Windows batch script that tracks screen time in 4 batches, updates every second, and plays a beep sound at batch transitions.

## Batches

| Batch | Time Range | Label |
|-------|------------|-------|
| 1 | 09:00 - 12:00 | Morning |
| 2 | 12:00 - 15:00 | Afternoon |
| 3 | 15:00 - 18:00 | Evening |
| 4 | 18:00 - 21:00 | Night |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SCREEN_TIME.BAT                          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   INPUT      │───▶│  PROCESSING  │───▶│   OUTPUT     │  │
│  │              │    │              │    │              │  │
│  │ %time% var   │    │ Parse HH:MM:SS│   │ cls + echo   │  │
│  │ (system)     │    │ Total seconds │   │ Batch name   │  │
│  └──────────────┘    │ Compare ranges│   │ Remaining    │  │
│                      │ Transition?   │   │ HH:MM:SS     │  │
│                      └──────┬────────┘    └──────┬───────┘  │
│                             │                    │           │
│                      ┌──────▼────────┐           │           │
│                      │  BEEP LOGIC   │           │           │
│                      │               │           │           │
│                      │ prev_batch ≠  │           │           │
│                      │ current_batch │           │           │
│                      │ → beep 800Hz  │           │           │
│                      └───────────────┘           │           │
│                             │                    │           │
│                      ┌──────▼────────┐           │           │
│                      │  DELAY        │           │           │
│                      │ timeout /t 1  │           │           │
│                      └──────┬────────┘           │           │
│                             │                    │           │
│                      ┌──────▼────────┐           │           │
│                      │  LOOP BACK    │───────────┘           │
│                      └───────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

## Batch Transition Logic

```
TIME AXIS (seconds since midnight)
──────────────────────────────────────────────────────────────────▶
   0          32400        43200        54000        64800        75600      86400
   │          │            │            │            │            │          │
   ▼          ▼            ▼            ▼            ▼            ▼          ▼
┌──────┐  ┌────────┐   ┌────────┐    ┌────────┐   ┌────────┐  ┌────────┐
│ SLEEP│  │BATCH 1 │   │BATCH 2 │    │BATCH 3 │   │BATCH 4 │  │ SLEEP  │
│      │  │ 9-12   │   │ 12-15  │    │ 15-18  │   │ 18-21  │  │        │
└──────┘  └────────┘   └────────┘    └────────┘   └────────┘  └────────┘
    │        │           │            │            │           │
    │        │           │            │            │           │
    └────────┼───────────┼────────────┼────────────┼───────────┘
             │           │            │            │
             ▼           ▼            ▼            ▼
          BEEP        BEEP         BEEP         BEEP
         (9AM)       (12PM)       (3PM)        (6PM)
                                                      BEEP (9PM→next day)
```

## State Machine

```
                    ┌─────────────────────┐
                    │     STARTUP         │
                    │  prev_batch = ""    │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   GET CURRENT TIME  │
                    │  (hh, mm, ss)       │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  CALCULATE TOTAL    │
                    │  SECONDS            │
                    └──────────┬──────────┘
                               │
                               ▼
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
       ┌────────────┐   ┌────────────┐   ┌────────────┐
       │ total <    │   │ 9AM ≤ total│   │ 9PM ≤ total│
       │ 9AM (32400)│   │ < 9PM (75600)│ │ (next day) │
       └─────┬──────┘   └─────┬──────┘   └─────┬──────┘
             │                │                │
             ▼                ▼                ▼
    ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
    │ WAITING FOR   │ │ DETERMINE     │ │ WAITING FOR   │
    │ BATCH 1       │ │ ACTIVE BATCH  │ │ NEXT DAY      │
    │ rem = 9AM -   │ │ (1 of 4)      │ │ BATCH 1       │
    │ now           │ │ rem = end -   │ │ rem = 24h -   │
    └───────┬───────┘ │ now           │ │ now + 9AM     │
            │         └───────┬───────┘ └───────┬───────┘
            │                 │                 │
            └────────┬────────┴────────┬───────┘
                     ▼                 ▼
            ┌─────────────────────────────────┐
            │      TRANSITION CHECK           │
            │  if prev_batch ≠ current_batch  │
            │       → PLAY BEEP               │
            │  prev_batch = current_batch     │
            └─────────────────┬───────────────┘
                              │
                              ▼
            ┌─────────────────────────────────┐
            │      FORMAT & DISPLAY           │
            │  HH:MM:SS remaining             │
            └─────────────────┬───────────────┘
                              │
                              ▼
            ┌─────────────────────────────────┐
            │      DELAY 1 SECOND             │
            │  timeout /t 1 >nul              │
            └─────────────────┬───────────────┘
                              │
                              ▼
                         (LOOP BACK)
```

## Key Variables

| Variable | Purpose |
|----------|---------|
| `curr_time` | Raw `%time%` from system |
| `hh, mm, ss` | Parsed hour, minute, second |
| `total_sec` | Seconds since midnight |
| `b1_start..b4_end` | Batch boundaries (seconds) |
| `batch` | Current batch label |
| `rem` | Remaining seconds in batch |
| `prev_batch` | Previous iteration's batch |
| `rh, rmm, rs` | Formatted remaining H:M:S |

## Sound Implementation

```bat
powershell -c "[console]::beep(800,400)"
```

- **Frequency**: 800 Hz (mid-tone)
- **Duration**: 400 ms
- **Trigger**: Batch transition only (not on startup)
- **Method**: PowerShell console beep (native, no files needed)

## Edge Cases Handled

| Scenario | Behavior |
|----------|----------|
| Before 9 AM | Countdown to 9 AM (Batch 1) |
| Exactly at boundary | Shows new batch immediately |
| After 9 PM | Countdown to next day 9 AM |
| Single-digit hours | Zero-padded (e.g., "09") |
| First run | No beep (no prev_batch) |

## File Structure

```
D:\screen time\
├── screen_time.bat      # Main executable script
└── SCREEN_TIME_PLAN.md  # This documentation
```

## Usage

```cmd
# Run directly
screen_time.bat

# Or from command prompt
cmd /c screen_time.bat
```

## Customization Points

| Change | Location |
|--------|----------|
| Batch times | Lines 25-30 (b1_start, b1_end, etc.) |
| Beep frequency | Line 54 (800) |
| Beep duration | Line 54 (400) |
| Update interval | Line 73 (timeout /t 1) |
| Display format | Lines 60-68 |