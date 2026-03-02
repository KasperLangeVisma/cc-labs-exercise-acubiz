#!/bin/bash

# Factory Inventory Management System - Startup Script
# This script starts both the backend (FastAPI) and frontend (Vue + Vite) servers

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print a startup banner to indicate the application is launching, then resolve
# the script's absolute path so all subsequent commands reference the correct project root.
echo -e "${BLUE}Starting Factory Inventory Management System...${NC}\n"

# Get the project root directory (parent of scripts directory)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Detect the operating system (macOS, Linux, or Windows/Git-Bash) so the correct
# package manager and installation commands can be selected in the steps below.
# ── Detect OS ─────────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "${OS}" in
    Linux*)               MACHINE=Linux ;;
    Darwin*)              MACHINE=macOS ;;
    MINGW*|MSYS*|CYGWIN*) MACHINE=Windows ;;
    *)
        echo -e "${RED}Unsupported OS: ${OS}. Supported: macOS, Linux, Windows (Git Bash).${NC}"
        exit 1
        ;;
esac

# ── Install uv (Python package/venv manager) ──────────────────────────────────
if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}uv not found. Installing uv...${NC}"
    if [ "$MACHINE" = "Windows" ]; then
        powershell.exe -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    else
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    export PATH="$HOME/.local/bin:$PATH"
    echo -e "${GREEN}uv installed successfully.${NC}"
fi

# ── Install Node.js / npm ─────────────────────────────────────────────────────
if ! command -v npm &> /dev/null; then
    echo -e "${YELLOW}npm not found. Installing Node.js and npm...${NC}"
    if [ "$MACHINE" = "macOS" ]; then
        if command -v brew &> /dev/null; then
            brew install node
        else
            # Homebrew not available — install Node.js via nvm
            echo -e "${YELLOW}Homebrew not found. Installing Node.js via nvm...${NC}"
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            nvm install --lts
        fi
    elif [ "$MACHINE" = "Linux" ]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y nodejs npm
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y nodejs npm
        elif command -v yum &> /dev/null; then
            sudo yum install -y nodejs npm
        else
            echo -e "${RED}No supported package manager found (apt-get, dnf, yum).${NC}"
            echo -e "${RED}Please install Node.js manually: https://nodejs.org${NC}"
            exit 1
        fi
    elif [ "$MACHINE" = "Windows" ]; then
        if command -v winget &> /dev/null; then
            winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
            export PATH="/c/Program Files/nodejs:$PATH"
        elif command -v choco &> /dev/null; then
            choco install nodejs-lts -y
        elif command -v scoop &> /dev/null; then
            scoop install nodejs-lts
        else
            echo -e "${RED}No supported package manager found (winget, choco, scoop).${NC}"
            echo -e "${RED}Please install Node.js manually: https://nodejs.org${NC}"
            exit 1
        fi
    fi
    echo -e "${GREEN}Node.js and npm installed successfully.${NC}"
fi

# Check if backend dependencies are installed
if [ ! -d "$PROJECT_ROOT/server/.venv" ]; then
    echo -e "${YELLOW}Backend dependencies not found. Installing...${NC}"
    cd "$PROJECT_ROOT/server"
    uv venv
    uv sync
fi

# Check if frontend dependencies are installed
if [ ! -d "$PROJECT_ROOT/client/node_modules" ]; then
    echo -e "${YELLOW}Frontend dependencies not found. Installing...${NC}"
    cd "$PROJECT_ROOT/client"
    npm install
fi

# Start backend server in background
echo -e "${GREEN}Starting backend server on http://localhost:8001${NC}"
cd "$PROJECT_ROOT/server"
uv run python main.py > /tmp/inventory-backend.log 2>&1 &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 2

# Start frontend server in background
echo -e "${GREEN}Starting frontend server on http://localhost:3000${NC}"
cd "$PROJECT_ROOT/client"
npm run dev > /tmp/inventory-frontend.log 2>&1 &
FRONTEND_PID=$!

# Wait a moment for frontend to start
sleep 2

echo -e "\n${GREEN}✓ Application started successfully!${NC}"
echo -e "${BLUE}Frontend:${NC} http://localhost:3000"
echo -e "${BLUE}Backend API:${NC} http://localhost:8001"
echo -e "${BLUE}API Docs:${NC} http://localhost:8001/docs"
echo -e "\n${YELLOW}Logs:${NC}"
echo -e "  Backend: /tmp/inventory-backend.log"
echo -e "  Frontend: /tmp/inventory-frontend.log"
echo -e "\n${YELLOW}To stop the servers, run:${NC} ./stop.sh"
echo -e "${YELLOW}Or press Ctrl+C and then run:${NC} kill $BACKEND_PID $FRONTEND_PID"

# Save PIDs to file for stop script
echo "$BACKEND_PID" > /tmp/inventory-backend.pid
echo "$FRONTEND_PID" > /tmp/inventory-frontend.pid

# Wait for Ctrl+C
trap "echo -e '\n${YELLOW}Shutting down servers...${NC}'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; rm -f /tmp/inventory-*.pid; exit 0" INT TERM

echo -e "\n${GREEN}Press Ctrl+C to stop all servers${NC}"
wait
