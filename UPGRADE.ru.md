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

### Шаг 3: Использовать новые команды установки

Теперь доступны автоматизированные команды:

```bash
# Проверить что будет обновлено (без изменения файлов)
mix phoenix_kit.gen.routes --dry-run

# Обновить router конфигурацию
mix phoenix_kit.gen.routes --force

# Обновить миграции (если появились новые)
mix phoenix_kit.gen.migration

# Полная переустановка (осторожно!)
mix phoenix_kit.install --force
```

### Шаг 4: Проверить изменения

1. **Router configuration** - убедитесь что routes правильно обновлены:
   ```elixir
   # Должно быть:
   import BeamLab.PhoenixKitWeb.UserAuth,
     only: [fetch_current_scope_for_user: 2, redirect_if_user_is_authenticated: 2, require_authenticated_user: 2]
   
   # В browser pipeline:
   plug :fetch_current_scope_for_user
   ```

2. **Configuration** - проверьте `config/config.exs`:
   ```elixir
   config :phoenix_kit, mode: :library
   ```

3. **Migrations** - запустите новые миграции:
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
```bash
# Покажет что нужно исправить
mix phoenix_kit.gen.routes --dry-run

# Автоматически исправит
mix phoenix_kit.gen.routes --force
```

### Проблема: Миграции уже существуют

**Симптом:** Ошибки о дублирующих миграциях

**Решение:**
```bash
# Проверить существующие миграции
ls priv/repo/migrations/ | grep phoenix_kit

# Удалить старые миграции PhoenixKit (осторожно!)
rm priv/repo/migrations/*phoenix_kit*

# Создать новые
mix phoenix_kit.gen.migration
```

### Проблема: Конфликты конфигурации

**Симптом:** Дублирующая конфигурация в config.exs

**Решение:**
```bash
# Удалить старые строки PhoenixKit из config/config.exs
# Затем запустить:
mix phoenix_kit.install --no-migrations
```

## 📋 Checklist обновления

- [ ] Обновил dependency в mix.exs
- [ ] Запустил `mix deps.update phoenix_kit`
- [ ] Проверил router configuration
- [ ] Обновил миграции
- [ ] Проверил конфигурацию
- [ ] Протестировал компиляцию
- [ ] Протестировал запуск сервера
- [ ] Проверил авторизацию работает

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
3. Приложите вывод команд `mix compile` и `mix phoenix_kit.install --dry-run`