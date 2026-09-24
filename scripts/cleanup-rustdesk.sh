#!/bin/bash
set -e

echo "=========================================="
echo "  Полная очистка RustDesk из macOS"
echo "=========================================="

# 1. Завершение запущенных процессов
echo "==> Завершение процессов RustDesk..."
killall RustDesk 2>/dev/null || true
killall rustdesk 2>/dev/null || true
killall service 2>/dev/null || true

# 2. Выгрузка и удаление системных служб (LaunchDaemons / LaunchAgents)
echo "==> Выгрузка и удаление системных служб..."
if [[ -f "/Library/LaunchDaemons/com.carriez.rustdesk.service.plist" ]]; then
    sudo launchctl unload "/Library/LaunchDaemons/com.carriez.rustdesk.service.plist" 2>/dev/null || true
    sudo rm -f "/Library/LaunchDaemons/com.carriez.rustdesk.service.plist"
fi
if [[ -f "/Library/LaunchAgents/com.carriez.rustdesk_server.plist" ]]; then
    sudo launchctl unload "/Library/LaunchAgents/com.carriez.rustdesk_server.plist" 2>/dev/null || true
    sudo rm -f "/Library/LaunchAgents/com.carriez.rustdesk_server.plist"
fi

# 3. Сброс системных разрешений TCC (Запись экрана, Универсальный доступ и т.д.)
echo "==> Сброс разрешений macOS (TCC)..."
tccutil reset All com.carriez.rustdesk 2>/dev/null || true
tccutil reset ScreenCapture com.carriez.rustdesk 2>/dev/null || true
tccutil reset Accessibility com.carriez.rustdesk 2>/dev/null || true
tccutil reset InputMonitoring com.carriez.rustdesk 2>/dev/null || true
tccutil reset Microphone com.carriez.rustdesk 2>/dev/null || true

# 4. Удаление конфигураций, логов и кэша
echo "==> Удаление конфигураций, кэша и логов..."
rm -rf "$HOME/Library/Logs/RustDesk"
rm -rf "$HOME/Library/Logs/rustdesk"
rm -rf "$HOME/Library/Caches/com.carriez.rustdesk"
rm -rf "$HOME/Library/Caches/RustDesk"
rm -rf "$HOME/Library/Caches/rustdesk"
rm -rf "$HOME/Library/Application Support/RustDesk"
rm -rf "$HOME/Library/Application Support/rustdesk"
rm -rf "$HOME/Library/Preferences/com.carriez.rustdesk"
rm -f  "$HOME/Library/Preferences/com.carriez.rustdesk.plist"
rm -rf "$HOME/Library/Saved Application State/com.carriez.rustdesk.savedState"

# Временные файлы и сокеты
rm -rf /tmp/RustDesk*
rm -rf /tmp/rustdesk*
rm -rf /tmp/.rustdesk*

# 5. Удаление установленного приложения
echo "==> Удаление RustDesk.app из /Applications..."
if [[ -d "/Applications/RustDesk.app" ]]; then
    sudo rm -rf "/Applications/RustDesk.app"
fi
rm -rf "$HOME/Applications/RustDesk.app"

echo "=========================================="
echo "  Очистка RustDesk успешно завершена!"
echo "=========================================="
