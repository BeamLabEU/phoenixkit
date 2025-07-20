# PhoenixKit Testing Guide

Руководство по тестированию PhoenixKit в качестве модуля в Phoenix приложении.

## 🧪 Ручное тестирование

### Создание тестового проекта

```bash
# Создать новый Phoenix проект
mix phx.new test_phoenix_kit --no-live --no-dashboard --no-mailer
cd test_phoenix_kit

# Добавить PhoenixKit в mix.exs
```

В `mix.exs` добавьте dependency:

```elixir
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"},
    # ... остальные dependencies
  ]
end
```

### Пошаговое тестирование

1. **Установка зависимостей:**
   ```bash
   mix deps.get
   ```

2. **Компиляция проекта:**
   ```bash
   mix compile
   ```

3. **Проверка доступности Mix tasks:**
   ```bash
   mix help | grep phoenix_kit
   ```
   
   Должно показать:
   ```
   mix phoenix_kit.gen.migration # Generates PhoenixKit database migrations
   mix phoenix_kit.gen.routes    # Generates PhoenixKit authentication routes in your router
   mix phoenix_kit.install       # Installs PhoenixKit authentication library into your Phoenix application
   ```

4. **Генерация миграций:**
   ```bash
   mix phoenix_kit.gen.migration
   ```
   
   Проверка:
   ```bash
   ls priv/repo/migrations/*phoenix_kit*
   ```

5. **Создание БД и запуск миграций:**
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

6. **Тестирование router (dry-run):**
   ```bash
   mix phoenix_kit.gen.routes --dry-run
   ```

7. **Генерация router конфигурации:**
   ```bash
   mix phoenix_kit.gen.routes --force
   ```
   
   Проверка:
   ```bash
   grep -A 10 -B 5 "BeamLab.PhoenixKitWeb" lib/test_phoenix_kit_web/router.ex
   ```

8. **Полная установка:**
   ```bash
   mix phoenix_kit.install --force
   ```

9. **Финальная компиляция:**
   ```bash
   mix compile
   ```

10. **Запуск сервера:**
    ```bash
    mix phx.server
    ```

### Тестирование в браузере

1. Откройте http://localhost:4000
2. Перейдите на http://localhost:4000/auth/register
3. Зарегистрируйте пользователя
4. Попробуйте логин на http://localhost:4000/auth/log-in
5. Проверьте настройки на http://localhost:4000/auth/settings

## 🔧 Решение проблем

### Проблема: Mix tasks не найдены

**Причина:** PhoenixKit не скомпилирован или не загружен.

**Решение:**
```bash
mix deps.compile phoenix_kit --force
mix compile
```

### Проблема: Router ошибки

**Причина:** Конфликт с существующими routes.

**Решение:**
```bash
# Посмотреть что будет изменено
mix phoenix_kit.gen.routes --dry-run

# Принудительно обновить
mix phoenix_kit.gen.routes --force
```

### Проблема: Ошибки миграций

**Причина:** Миграции уже существуют.

**Решение:**
```bash
# Проверить существующие миграции
ls priv/repo/migrations/

# Удалить конфликтующие (осторожно!)
rm priv/repo/migrations/*phoenix_kit*

# Сгенерировать заново
mix phoenix_kit.gen.migration
```

### Проблема: Компиляция не удается

**Причина:** Отсутствующие зависимости или конфликты.

**Решение:**
```bash
# Очистить и пересобрать
mix deps.clean --all
mix deps.get
mix compile
```

## 📋 Checklist тестирования

- [ ] Создан тестовый Phoenix проект
- [ ] PhoenixKit добавлен в dependencies
- [ ] `mix deps.get` успешно
- [ ] `mix compile` без ошибок
- [ ] Mix tasks `phoenix_kit.*` доступны
- [ ] Миграции генерируются
- [ ] База данных создается и мигрируется
- [ ] Router конфигурируется
- [ ] Проект компилируется после изменений
- [ ] Сервер запускается
- [ ] Registration страница работает
- [ ] Login страница работает
- [ ] Settings страница работает

## 🚀 Упрощенный тест

Для быстрой проверки основной функциональности:

```bash
# Создать проект
mix phx.new quick_test --no-live --no-dashboard --no-mailer
cd quick_test

# Добавить в mix.exs:
# {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}

# Установить
mix deps.get
mix compile

# Проверить tasks
mix help | grep phoenix_kit

# Установить PhoenixKit
mix phoenix_kit.install
mix ecto.create
mix ecto.migrate

# Запустить
mix phx.server
# Открыть http://localhost:4000/auth/register
```

## 📞 Помощь

Если возникают проблемы:

1. Убедитесь что используете Phoenix 1.8+
2. Проверьте что все зависимости установлены
3. Проверьте логи ошибок
4. Создайте issue на GitHub с деталями

### Логи для диагностики

```bash
# Проверить версии
mix --version
mix phx.server --version

# Проверить зависимости
mix deps.tree

# Проверить компиляцию
mix compile --verbose

# Проверить routes
mix phx.routes
```