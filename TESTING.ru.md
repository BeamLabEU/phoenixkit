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

3. **Проверка zero-configuration setup:**
   ```elixir
   # Убедиться что PhoenixKit доступен
   iex -S mix
   BeamLab.PhoenixKit.version()
   ```
   
   Должно вернуть:
   ```
   "1.0.0"
   ```

4. **Добавление таблиц базы данных:**
   ```bash
   # Создать файл миграции
   mix ecto.gen.migration add_phoenix_kit_auth_tables
   ```
   
   Скопируйте содержимое миграции из `deps/phoenix_kit/priv/repo/migrations/` или добавьте таблицы вручную. Проверка:
   ```bash
   ls priv/repo/migrations/*phoenix_kit*
   ```

5. **Создание БД и запуск миграций:**
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

6. **Настройка router (zero-configuration):**
   Отредактируйте `lib/test_phoenix_kit_web/router.ex`:
   ```elixir
   defmodule TestPhoenixKitWeb.Router do
     use TestPhoenixKitWeb, :router
     import BeamLab.PhoenixKitWeb.Router  # ← Добавить этот import

     pipeline :browser do
       plug :accepts, ["html"]
       plug :fetch_session
       plug :fetch_live_flash
       plug :put_root_layout, html: {TestPhoenixKitWeb.Layouts, :root}
       plug :protect_from_forgery
       plug :put_secure_browser_headers
       plug :fetch_current_scope_for_user  # ← Добавить PhoenixKit auth
     end

     scope "/" do
       pipe_through :browser
       get "/", PageController, :home
     end

     # PhoenixKit аутентификация - ОДНА СТРОКА!
     phoenix_kit()  # ← Вот и всё!
   end
   ```
   
   Проверить setup:
   ```bash
   grep -A 5 "phoenix_kit()" lib/test_phoenix_kit_web/router.ex
   ```

7. **Финальная компиляция:**
   ```bash
   mix compile
   ```

8. **Запуск сервера:**
    ```bash
    mix phx.server
    ```

### Тестирование в браузере

1. Откройте http://localhost:4000
2. Перейдите на http://localhost:4000/phoenix_kit/register
3. Зарегистрируйте пользователя
4. Попробуйте логин на http://localhost:4000/phoenix_kit/log-in
5. Проверьте настройки на http://localhost:4000/phoenix_kit/settings

## 🔧 Решение проблем

### Проблема: Модули PhoenixKit не найдены

**Причина:** PhoenixKit не скомпилирован или не загружен.

**Решение:**
```bash
mix deps.compile phoenix_kit --force
mix compile

# Проверить доступность:
iex -S mix
BeamLab.PhoenixKit.version()
```

### Проблема: Router ошибки

**Причина:** Отсутствуют import'ы или неправильная конфигурация.

**Решение:**
Убедитесь что в вашем router правильная настройка:
```elixir
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import BeamLab.PhoenixKitWeb.Router  # ← Обязательно нужен

  pipeline :browser do
    # ... другие plug'и ...
    plug :fetch_current_scope_for_user  # ← Обязательно нужен
  end

  # Обязательно нужен этот вызов макроса
  phoenix_kit()
end
```

### Проблема: Ошибки миграций

**Причина:** Миграции уже существуют или отсутствуют таблицы.

**Решение:**
```bash
# Проверить существующие миграции
ls priv/repo/migrations/

# Если есть старые, удалить их (осторожно!)
rm priv/repo/migrations/*phoenix_kit*

# Скопировать правильную миграцию из deps:
cp deps/phoenix_kit/priv/repo/migrations/* priv/repo/migrations/

# Или создать вручную:
mix ecto.gen.migration add_phoenix_kit_auth_tables
# Затем добавить содержимое миграции из README.md
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
- [ ] Модули PhoenixKit доступны (`BeamLab.PhoenixKit.version()`)
- [ ] Миграция базы данных создана и применена
- [ ] Router настроен через zero-config подход
- [ ] Макрос `phoenix_kit()` добавлен в routes
- [ ] Проект компилируется после изменений в router
- [ ] Сервер запускается
- [ ] Registration страница работает (/phoenix_kit/register)
- [ ] Login страница работает (/phoenix_kit/log-in)
- [ ] Settings страница работает (/phoenix_kit/settings)

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

# Создать базу данных
mix ecto.create

# Добавить миграцию базы данных
mix ecto.gen.migration add_phoenix_kit_auth_tables
# Скопировать содержимое миграции из deps/phoenix_kit/priv/repo/migrations/
# Или добавить таблицы вручную как показано в README.md

# Запустить миграцию
mix ecto.migrate

# Обновить router.ex через zero-config setup:
# import BeamLab.PhoenixKitWeb.Router
# Добавить plug :fetch_current_scope_for_user в browser pipeline  
# Добавить макрос phoenix_kit()

# Запустить
mix phx.server
# Открыть http://localhost:4000/phoenix_kit/register
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
elixir --version

# Проверить зависимости
mix deps.tree

# Проверить доступность PhoenixKit
iex -S mix
BeamLab.PhoenixKit.version()

# Проверить компиляцию
mix compile --verbose

# Проверить routes (должны видеть /phoenix_kit/* routes)
mix phx.routes
```