@echo off
cd /d "%~dp0privacy_site"
REM Workaround for non-ASCII computer name error in Vercel CLI
set COMPUTERNAME=ITPASS-BUILDER
echo ==========================================
echo Deploying to Vercel
echo ==========================================
echo.
echo This command will:
echo 1. Install Vercel CLI (if missing) -> Type 'y' if asked.
echo 2. Ask you to Log In -> It will open your browser.
echo 3. Ask "Set up and deploy?" -> Type 'y'.
echo 4. Ask about Project Settings -> Press Enter for all defaults.
echo.
echo Starting...
echo.

call npx vercel

echo.
echo Deployment finished (if successful).
pause
