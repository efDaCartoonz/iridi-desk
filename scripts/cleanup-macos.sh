#!/bin/bash
set -e

echo "=========================================="
echo "  Полная очистка iRidiDesk из macOS"
echo "=========================================="

# 1. Завершение запущенных процессов
echo "==> Завершение процессов iRidiDesk..."
killall iRidiDesk 2>/dev/null || true
killall service 2>/dev/null || true

# 2. Выгрузка и удаление системных служб (LaunchDaemons / LaunchAgents)
echo "==> Выгрузка и удаление системных служб..."
if [[ -f "/Library/LaunchDaemons/com.iridi.desk.service.plist" ]]; then
    sudo launchctl unload "/Library/LaunchDaemons/com.iridi.desk.service.plist" 2>/dev/null || true
    sudo rm -f "/Library/LaunchDaemons/com.iridi.desk.service.plist"
fi
if [[ -f "/Library/LaunchAgents/com.iridi.desk_server.plist" ]]; then
    sudo launchctl unload "/Library/LaunchAgents/com.iridi.desk_server.plist" 2>/dev/null || true
    sudo rm -f "/Library/LaunchAgents/com.iridi.desk_server.plist"
fi

# 3. Сброс системных разрешений TCC (Запись экрана, Универсальный доступ и т.д.)
echo "==> Сброс разрешений macOS (TCC)..."
tccutil reset All com.iridi.desk 2>/dev/null || true
tccutil reset ScreenCapture com.iridi.desk 2>/dev/null || true
tccutil reset Accessibility com.iridi.desk 2>/dev/null || true
tccutil reset InputMonitoring com.iridi.desk 2>/dev/null || true
tccutil reset Microphone com.iridi.desk 2>/dev/null || true

# 4. Удаление конфигураций, логов и кэша
echo "==> Удаление конфигураций, кэша и логов..."
rm -rf "$HOME/Library/Logs/iRidiDesk"
rm -rf "$HOME/Library/Caches/com.iridi.desk"
rm -rf "$HOME/Library/Caches/iRidiDesk"
rm -rf "$HOME/Library/Application Support/iRidiDesk"
rm -rf "$HOME/Library/Preferences/com.iridi.desk"
rm -f  "$HOME/Library/Preferences/com.iridi.desk.plist"
rm -rf "$HOME/Library/Saved Application State/com.iridi.desk.savedState"

# Временные файлы и сокеты
rm -rf /tmp/iRidiDesk*
rm -rf /tmp/.irididesk*

# 5. Удаление установленного приложения
echo "==> Удаление iRidiDesk.app из /Applications..."
if [[ -d "/Applications/iRidiDesk.app" ]]; then
    sudo rm -rf "/Applications/iRidiDesk.app"
fi
rm -rf "$HOME/Applications/iRidiDesk.app"

echo "=========================================="
echo "  Очистка успешно завершена!"
echo "=========================================="
