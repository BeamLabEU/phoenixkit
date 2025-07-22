# PhoenixKit Upgrade Guide

Руководство по обновлению PhoenixKit до последних версий в существующих проектах.

## 🚀 Обновление до v1.0.0+ (Автоматизированная установка)

### Шаг 1: Обновить dependency

В `mix.exs` обновите версию:

```elixir
def deps do
  [
    # Старая версия:
    # {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v0.x.x"}
    
    # Новая версия:
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}
  ]
end
```

### Шаг 2: Обновить зависимости

```bash
mix deps.update phoenix_kit
mix deps.get
```

### Шаг 3: Zero-Configuration настройка

В v1.0.0+ PhoenixKit использует zero-configuration подход:

```elixir
# В lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import BeamLab.PhoenixKitWeb.Router  # ← Добавить этот import

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YourAppWeb.Layouts, :root}
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

### Шаг 4: Добавить таблицы БД

```bash
# Создать файл миграции
mix ecto.gen.migration add_phoenix_kit_auth_tables
```

Скопируйте содержимое миграции из `deps/phoenix_kit/priv/repo/migrations/` или добавьте это:

```elixir
defmodule YourApp.Repo.Migrations.AddPhoenixKitAuthTables do
  use Ecto.Migration

  def change do
    create table(:phoenix_kit_users) do
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    create unique_index(:phoenix_kit_users, [:email])

    create table(:phoenix_kit_users_tokens) do
      add :user_id, references(:phoenix_kit_users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:phoenix_kit_users_tokens, [:user_id])
    create unique_index(:phoenix_kit_users_tokens, [:context, :token])
  end
end
```

Затем запустите:
```bash
mix ecto.migrate
```

### Шаг 5: Тестирование

```bash
# Проверить компиляцию
mix compile

# Запустить тесты
mix test

# Запустить сервер
mix phx.server
```

## 🛠️ Решение проблем при обновлении

### Проблема: Router конфликты

**Симптом:** Ошибки компиляции в router.ex

**Решение:**
Убедитесь что у вас правильная настройка import и plugin:
```elixir
# В lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import BeamLab.PhoenixKitWeb.Router  # ← Обязательно нужен этот import

  pipeline :browser do
    # ... другие plug'и ...
    plug :fetch_current_scope_for_user  # ← Обязательно нужен этот plug
  end

  # Обязательно нужен этот вызов макроса
  phoenix_kit()
end
```

### Проблема: Миграции уже существуют

**Симптом:** Ошибки о дублирующих миграциях

**Решение:**
```bash
# Проверить существующие миграции
ls priv/repo/migrations/ | grep phoenix_kit

# Если у вас есть старые миграции PhoenixKit, удалите их (осторожно!)
rm priv/repo/migrations/*phoenix_kit*

# Скопируйте правильную миграцию из deps
cp deps/phoenix_kit/priv/repo/migrations/* priv/repo/migrations/

# Или создайте вручную с содержимым миграции выше
mix ecto.gen.migration add_phoenix_kit_auth_tables
```

### Проблема: Конфликты конфигурации

**Симптом:** Дублирующая конфигурация в config.exs

**Решение:**
Убедитесь что у вас настроен library mode:
```elixir
# config/config.exs
config :phoenix_kit, mode: :library
```

Удалите старые строки конфигурации PhoenixKit. Zero-config подходу нужна минимальная конфигурация.

## 📋 Checklist обновления

- [ ] Обновил dependency в mix.exs до v1.0.0+
- [ ] Запустил `mix deps.update phoenix_kit`
- [ ] Добавил `import BeamLab.PhoenixKitWeb.Router` в router
- [ ] Добавил `plug :fetch_current_scope_for_user` в browser pipeline
- [ ] Добавил `phoenix_kit()` макрос в routes
- [ ] Создал и запустил миграции базы данных
- [ ] Протестировал компиляцию
- [ ] Протестировал запуск сервера
- [ ] Проверил что authentication routes работают (/phoenix_kit/register, /phoenix_kit/log-in)

## 🆘 Откат к предыдущей версии

Если что-то пошло не так:

1. **Откатить dependency:**
   ```elixir
   {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v0.x.x"}
   ```

2. **Откатить миграции:**
   ```bash
   mix ecto.rollback --step 1
   ```

3. **Восстановить файлы из git:**
   ```bash
   git restore lib/your_app_web/router.ex
   git restore config/config.exs
   ```

## 📞 Поддержка

При проблемах с обновлением:

1. Проверьте [Issues на GitHub](https://github.com/BeamLabEU/phoenixkit/issues)
2. Создайте новый issue с деталями проблемы
3. Приложите вывод команды `mix compile` и убедитесь что ваша настройка router соответствует zero-config паттерну выше