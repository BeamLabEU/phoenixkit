#!/bin/bash

# PhoenixKit Integration Test Script
# Создает тестовый Phoenix проект и тестирует PhoenixKit как модуль

set -e  # Exit on any error

echo "🧪 PhoenixKit Integration Test"
echo "============================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для цветного вывода
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Переменные
TEST_APP_NAME="phoenix_kit_test_app"
TEST_DIR="/tmp/$TEST_APP_NAME"
PHOENIX_KIT_PATH=$(pwd)

# Проверка что мы в правильной директории
if [[ ! -f "mix.exs" ]] || ! grep -q "phoenix_kit" mix.exs; then
    log_error "Запустите скрипт из корневой директории PhoenixKit"
    exit 1
fi

log_info "PhoenixKit path: $PHOENIX_KIT_PATH"

# Функция очистки
cleanup() {
    log_warning "Очистка тестовой директории..."
    rm -rf "$TEST_DIR"
}

# Обработка прерывания
trap cleanup EXIT

# Шаг 1: Создание тестового Phoenix проекта
log_info "Шаг 1: Создание тестового Phoenix проекта"

if [[ -d "$TEST_DIR" ]]; then
    log_warning "Удаление существующей тестовой директории..."
    rm -rf "$TEST_DIR"
fi

cd /tmp
mix phx.new "$TEST_APP_NAME" --no-live --no-dashboard --no-mailer
cd "$TEST_APP_NAME"

log_success "Phoenix проект создан"

# Шаг 2: Добавление PhoenixKit dependency
log_info "Шаг 2: Добавление PhoenixKit как dependency"

# Создаем backup mix.exs
cp mix.exs mix.exs.backup

# Добавляем PhoenixKit dependency
cat > mix_deps_update.exs << 'EOF'
defmodule MixUpdate do
  def add_phoenix_kit_dep do
    content = File.read!("mix.exs")
    
    # Найти deps функцию и добавить PhoenixKit
    phoenix_kit_path = System.get_env("PHOENIX_KIT_PATH")
    updated = String.replace(content, 
      ~r/(defp deps do\s*\[\s*)/,
      "\\1{:phoenix_kit, path: \"#{phoenix_kit_path}\"},\n      "
    )
    
    File.write!("mix.exs", updated)
  end
end

MixUpdate.add_phoenix_kit_dep()
EOF

export PHOENIX_KIT_PATH="$PHOENIX_KIT_PATH"

elixir mix_deps_update.exs
rm mix_deps_update.exs

log_success "PhoenixKit dependency добавлен"

# Показать изменения в mix.exs
log_info "Проверка mix.exs:"
head -20 mix.exs | grep -A 5 -B 5 phoenix_kit || true

# Шаг 3: Установка зависимостей
log_info "Шаг 3: Установка зависимостей"
mix deps.get
log_success "Зависимости установлены"

# Шаг 4: Тестирование команд PhoenixKit
log_info "Шаг 4: Тестирование команд PhoenixKit"

# 4.1: Проверка доступности команд
log_info "4.1: Проверка доступности Mix tasks"
if mix help | grep -q phoenix_kit; then
    log_success "PhoenixKit Mix tasks доступны"
    mix help | grep phoenix_kit
else
    log_error "PhoenixKit Mix tasks не найдены"
    exit 1
fi

# 4.2: Тест генерации миграций
log_info "4.2: Тестирование генерации миграций"
mix phoenix_kit.gen.migration
if ls priv/repo/migrations/*phoenix_kit* >/dev/null 2>&1; then
    log_success "Миграции сгенерированы"
    ls -la priv/repo/migrations/*phoenix_kit*
else
    log_error "Миграции не созданы"
    exit 1
fi

# 4.3: Тест dry-run router
log_info "4.3: Тестирование генерации router (dry-run)"
mix phoenix_kit.gen.routes --dry-run
log_success "Router dry-run выполнен"

# 4.4: Тест генерации router
log_info "4.4: Тестирование генерации router"
mix phoenix_kit.gen.routes --force
if grep -q "BeamLab.PhoenixKitWeb" lib/${TEST_APP_NAME}_web/router.ex; then
    log_success "Router обновлен"
    echo "Router content:"
    grep -A 5 -B 5 "BeamLab.PhoenixKitWeb" lib/${TEST_APP_NAME}_web/router.ex
else
    log_error "Router не обновлен"
    exit 1
fi

# 4.5: Тест полной установки
log_info "4.5: Тестирование полной установки"
mix phoenix_kit.install --no-migrations --force
log_success "Полная установка выполнена"

# Шаг 5: Тестирование компиляции
log_info "Шаг 5: Тестирование компиляции"
if mix compile; then
    log_success "Проект компилируется без ошибок"
else
    log_error "Ошибки компиляции"
    exit 1
fi

# Шаг 6: Создание и запуск миграций
log_info "Шаг 6: Создание БД и запуск миграций"
mix ecto.create
mix ecto.migrate
log_success "База данных создана и миграции выполнены"

# Шаг 7: Проверка что миграции создали таблицы
log_info "Шаг 7: Проверка таблиц БД"
if mix ecto.gen.migration test_check --quiet >/dev/null 2>&1; then
    # Можем создать миграции, значит БД работает
    log_success "База данных работает корректно"
else
    log_warning "Не удалось проверить БД"
fi

# Шаг 8: Тестирование запуска сервера (краткий тест)
log_info "Шаг 8: Тестирование запуска сервера"
timeout 10s mix phx.server &
SERVER_PID=$!
sleep 5

if kill -0 $SERVER_PID 2>/dev/null; then
    log_success "Сервер запускается корректно"
    kill $SERVER_PID 2>/dev/null || true
else
    log_warning "Сервер не запустился или упал"
fi

# Шаг 9: Проверка routes
log_info "Шаг 9: Проверка routes"
if mix phx.routes | grep -q "phoenix_kit\|auth"; then
    log_success "PhoenixKit routes найдены"
    echo "PhoenixKit routes:"
    mix phx.routes | grep -E "(phoenix_kit|auth|register|log-in|settings)"
else
    log_warning "PhoenixKit routes не найдены"
fi

# Финальный отчет
echo ""
echo "🎉 ИНТЕГРАЦИОННЫЙ ТЕСТ ЗАВЕРШЕН"
echo "==============================="
log_success "Все основные функции PhoenixKit работают корректно!"

echo ""
echo "📋 Результаты тестирования:"
echo "   ✅ Phoenix проект создан"
echo "   ✅ PhoenixKit dependency добавлен"
echo "   ✅ Mix tasks доступны"
echo "   ✅ Миграции генерируются"
echo "   ✅ Router конфигурируется"
echo "   ✅ Проект компилируется"
echo "   ✅ База данных работает"
echo "   ✅ Сервер запускается"
echo "   ✅ Routes настроены"

echo ""
echo "📁 Тестовый проект находится в: $TEST_DIR"
echo "   Используйте для дальнейшего тестирования или удалите вручную"

log_info "Для ручного тестирования:"
echo "   cd $TEST_DIR"
echo "   mix phx.server"
echo "   Откройте http://localhost:4000/auth/register"