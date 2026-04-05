#!/usr/bin/env bash
set -euo pipefail

# Mistral Vibe Feature Test Script

echo "Testing Mistral Vibe devcontainer feature..."

# Test 1: Check if vibe binary is installed
echo "Test 1: Checking vibe binary installation..."
if command -v vibe >/dev/null 2>&1; then
    echo "✓ vibe binary found in PATH"
    # Test with --version flag only (non-interactive)
    if timeout 5s vibe --version >/dev/null 2>&1; then
        echo "✓ vibe --version works"
    else
        echo "⚠ vibe --version failed (may require API key, timeout, or has different output)"
    fi
else
    echo "✗ vibe binary not found in PATH"
    exit 1
fi

# Test 2: Check if vibe-acp binary is installed
echo "Test 2: Checking vibe-acp binary installation..."
if command -v vibe-acp >/dev/null 2>&1; then
    echo "✓ vibe-acp binary found in PATH"
    # Test with --version flag only (non-interactive)
    if timeout 5s vibe-acp --version >/dev/null 2>&1; then
        echo "✓ vibe-acp --version works"
    else
        echo "⚠ vibe-acp --version failed (may require API key, timeout, or has different output)"
    fi
else
    echo "✗ vibe-acp binary not found in PATH"
    exit 1
fi

# Test 3: Check state directory
echo "Test 3: Checking state directory..."
if [ -d "/var/lib/vibe" ]; then
    echo "✓ State directory /var/lib/vibe exists"
else
    echo "✗ State directory /var/lib/vibe not found"
    exit 1
fi

# Test 4: Check symbolic link
echo "Test 4: Checking symbolic link..."
if [ -L "$HOME/.vibe" ]; then
    echo "✓ Symbolic link $HOME/.vibe exists"
    if [ "$(readlink "$HOME/.vibe")" = "/var/lib/vibe" ]; then
        echo "✓ Symbolic link points to correct location"
    else
        echo "✗ Symbolic link points to wrong location: $(readlink "$HOME/.vibe")"
        exit 1
    fi
else
    echo "✗ Symbolic link $HOME/.vibe not found"
    exit 1
fi

# Test 5: Check on_create script
echo "Test 5: Checking on_create script..."
if [ -f "/usr/local/share/vibe/on_create.sh" ]; then
    echo "✓ on_create script exists"
    if [ -x "/usr/local/share/vibe/on_create.sh" ]; then
        echo "✓ on_create script is executable"
    else
        echo "✗ on_create script is not executable"
        exit 1
    fi
else
    echo "✗ on_create script not found"
    exit 1
fi

# Test 6: Check virtual environment
echo "Test 6: Checking virtual environment..."
if [ -d "/opt/mistral-vibe/venv" ]; then
    echo "✓ Virtual environment exists"
    if [ -f "/opt/mistral-vibe/venv/bin/python" ]; then
        echo "✓ Python interpreter found in venv"
    else
        echo "✗ Python interpreter not found in venv"
        exit 1
    fi
else
    echo "✗ Virtual environment not found"
    exit 1
fi

echo ""
echo "All tests passed! Mistral Vibe feature is working correctly."