@echo off
rem ai-setup install (Windows, copy mode) - shared skills + global rules for Claude Code AND Codex
rem
rem   install.bat check   show what would change. Nothing is modified. RUN THIS FIRST on a PC that already has a setup.
rem   install.bat         install (existing different files are backed up first, never deleted)
rem
rem   Claude : %USERPROFILE%\.claude\CLAUDE.md , %USERPROFILE%\.claude\skills\<name>
rem   Codex  : %USERPROFILE%\.codex\AGENTS.md  , %USERPROFILE%\.agents\skills\<name>
rem   Per-PC : %USERPROFILE%\.ai-setup\paths.local.md  (created once, never overwritten)
rem
rem Re-run after every "git pull". bgrun/ct/cxt are Linux-only and are not installed here.
rem Only skills with the SAME NAME as the ones in this repo are replaced; your other skills are left alone.
setlocal EnableDelayedExpansion
set "REPO=%~dp0"
set "CLAUDE_DIR=%USERPROFILE%\.claude"
set "CODEX_DIR=%USERPROFILE%\.codex"
set "AGENTS_SKILLS=%USERPROFILE%\.agents\skills"
set "LOCAL_DIR=%USERPROFILE%\.ai-setup"
set "MODE=install"
if /i "%~1"=="check" set "MODE=check"
set "BACKUP=%LOCAL_DIR%\backup-%RANDOM%%RANDOM%"

echo [%MODE%] repo=%REPO%
echo.

call :state "%CLAUDE_DIR%\CLAUDE.md" ST_CLAUDE
call :state "%CODEX_DIR%\AGENTS.md" ST_CODEX
echo Claude global rules  %CLAUDE_DIR%\CLAUDE.md : !ST_CLAUDE!
echo Codex  global rules  %CODEX_DIR%\AGENTS.md : !ST_CODEX!
echo    ("different" = your existing file is copied to backup first, then replaced. Merge what you still need into the repo's AGENTS.global.md.)
for /d %%s in ("%REPO%skills\*") do (
  if exist "%CLAUDE_DIR%\skills\%%~nxs" (echo skill %%~nxs [claude] : exists - replaced after backup) else (echo skill %%~nxs [claude] : new)
  if exist "%AGENTS_SKILLS%\%%~nxs" (echo skill %%~nxs [codex]  : exists - replaced after backup) else (echo skill %%~nxs [codex]  : new)
)
if exist "%LOCAL_DIR%\paths.local.md" (echo paths.local.md : exists - kept) else (echo paths.local.md : will be created from example)
set "FB=missing"
if exist "%CODEX_DIR%\config.toml" findstr /c:"project_doc_fallback_filenames" "%CODEX_DIR%\config.toml" >nul 2>&1 && set "FB=present"
echo codex config fallback (read project CLAUDE.md) : !FB!
echo.
if "%MODE%"=="check" (
  echo Nothing was changed. Run "install.bat" to apply.
  goto :eof
)

for %%d in ("%CLAUDE_DIR%\skills" "%CODEX_DIR%" "%AGENTS_SKILLS%" "%LOCAL_DIR%") do if not exist "%%~d" mkdir "%%~d"

if "!ST_CLAUDE!"=="different" (
  if not exist "%BACKUP%\claude" mkdir "%BACKUP%\claude"
  copy /y "%CLAUDE_DIR%\CLAUDE.md" "%BACKUP%\claude\CLAUDE.md" >nul
  echo backup  CLAUDE.md to %BACKUP%\claude
)
if "!ST_CODEX!"=="different" (
  if not exist "%BACKUP%\codex" mkdir "%BACKUP%\codex"
  copy /y "%CODEX_DIR%\AGENTS.md" "%BACKUP%\codex\AGENTS.md" >nul
  echo backup  AGENTS.md to %BACKUP%\codex
)
copy /y "%REPO%AGENTS.global.md" "%CLAUDE_DIR%\CLAUDE.md" >nul && echo copy    %CLAUDE_DIR%\CLAUDE.md
copy /y "%REPO%AGENTS.global.md" "%CODEX_DIR%\AGENTS.md" >nul && echo copy    %CODEX_DIR%\AGENTS.md

for /d %%s in ("%REPO%skills\*") do (
  if exist "%CLAUDE_DIR%\skills\%%~nxs" robocopy "%CLAUDE_DIR%\skills\%%~nxs" "%BACKUP%\claude\skills\%%~nxs" /E /NFL /NDL /NJH /NJS /NP >nul
  if exist "%AGENTS_SKILLS%\%%~nxs" robocopy "%AGENTS_SKILLS%\%%~nxs" "%BACKUP%\codex\skills\%%~nxs" /E /NFL /NDL /NJH /NJS /NP >nul
  robocopy "%%s" "%CLAUDE_DIR%\skills\%%~nxs" /MIR /NFL /NDL /NJH /NJS /NP >nul
  robocopy "%%s" "%AGENTS_SKILLS%\%%~nxs" /MIR /NFL /NDL /NJH /NJS /NP >nul
  echo copy    skill %%~nxs  [claude + codex]
)

if not exist "%LOCAL_DIR%\paths.local.md" (
  if exist "%CLAUDE_DIR%\paths.local.md" (
    move "%CLAUDE_DIR%\paths.local.md" "%LOCAL_DIR%\paths.local.md" >nul
    echo move    paths.local.md to %LOCAL_DIR%
  ) else (
    copy /y "%REPO%paths.local.example.md" "%LOCAL_DIR%\paths.local.md" >nul
    echo create  %LOCAL_DIR%\paths.local.md   -- fill in this PC's real folders
  )
)

if "!FB!"=="missing" (
  if not exist "%CODEX_DIR%\config.toml" (
    >"%CODEX_DIR%\config.toml" echo project_doc_fallback_filenames = ["CLAUDE.md"]
    echo create  %CODEX_DIR%\config.toml
  ) else (
    echo NOTE    add this line at the VERY TOP of %CODEX_DIR%\config.toml so Codex reads each project's CLAUDE.md:
    echo             project_doc_fallback_filenames = ["CLAUDE.md"]
  )
)

echo.
echo Done. Next:
echo  - fill %LOCAL_DIR%\paths.local.md  (folders differ per PC)
echo  - playwright MCP: see mcp\playwright.md (optional; existing MCP registrations are NOT touched)
echo  - restart Claude Code / Codex
endlocal
goto :eof

:state
rem %1 = installed file, %2 = output var : new / same / different
set "%2=new"
if exist "%~1" (
  fc /b "%REPO%AGENTS.global.md" "%~1" >nul 2>&1
  if errorlevel 1 (set "%2=different") else (set "%2=same")
)
goto :eof
