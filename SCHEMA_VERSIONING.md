# PhoenixKit Schema Versioning & Migration Guide

PhoenixKit использует профессиональную систему версионирования схемы базы данных для безопасного обновления между версиями библиотеки.

## 🔄 Как это работает

### Автоматическое версионирование
- Каждая версия PhoenixKit имеет версию схемы (например, `1.0.0`)
- При первом обращении к аутентификации автоматически создается нужная схема
- Версия схемы сохраняется в таблице `phoenix_kit_schema_versions`
- При обновлении библиотеки автоматически применяются необходимые миграции

### Таблица версий
```sql
CREATE TABLE phoenix_kit_schema_versions (
  id bigserial PRIMARY KEY,
  version varchar(50) NOT NULL,
  applied_at timestamp NOT NULL DEFAULT NOW(),
  inserted_at timestamp NOT NULL DEFAULT NOW()
);
```

## 📦 Безопасное обновление библиотеки

### Автоматический режим (рекомендуется)
```elixir
# 1. Обновите версию в mix.exs
{:phoenix_kit, "~> 2.0"}

# 2. Установите зависимости
mix deps.get

# 3. При первом обращении к /phoenix_kit/register миграция применится автоматически
# Никаких дополнительных действий не требуется!
```

### Ручной режим (для production)
```bash
# 1. Проверьте статус схемы
mix phoenix_kit.migrate --status

# 2. Примените миграцию вручную
mix phoenix_kit.migrate

# 3. Или с указанием репозитория
mix phoenix_kit.migrate --repo MyApp.Repo
```

## 🔍 Управление миграциями

### Проверка статуса
```bash
$ mix phoenix_kit.migrate --status

PhoenixKit Schema Status
=======================

Repository: MyApp.Repo
Installed Version: 1.0.0
Target Version: 2.0.0
Migration Required: YES

📋 Action Required: Schema upgrade
   Upgrade from 1.0.0 to 2.0.0
   This is a safe operation that preserves existing data

To apply migration: mix phoenix_kit.migrate
```

### Применение миграции
```bash
$ mix phoenix_kit.migrate

Starting PhoenixKit schema migration...
From: 1.0.0
To: 2.0.0

⚠️  This will upgrade your PhoenixKit schema
   From version: 1.0.0
   To version: 2.0.0
   This operation preserves existing data

Proceed with schema upgrade? [Yn] y

Applying migration...
[info] [PhoenixKit] Schema migration from 1.0.0 to 2.0.0
[info] [PhoenixKit] Applying migration to schema version 2.0.0
[info] [PhoenixKit] Schema migration completed successfully

✅ Migration completed successfully!

PhoenixKit schema is now at version 2.0.0
Authentication tables are ready for use.
```

## 🛡️ Принципы безопасности

### 1. Сохранение данных
- ✅ Все миграции сохраняют существующие данные пользователей
- ✅ Добавляют новые колонки как nullable
- ✅ Используют `ALTER TABLE` вместо `DROP/CREATE`

### 2. Идемпотентность
- ✅ Миграции можно запускать несколько раз безопасно
- ✅ Используется `IF NOT EXISTS` и `IF EXISTS`
- ✅ Проверяется текущее состояние перед изменениями

### 3. Обратная совместимость
- ✅ Старые колонки не удаляются в minor версиях
- ✅ API остается совместимым между minor версиями
- ✅ Breaking changes только в major версиях

## 📋 Примеры миграций

### Версия 1.0.0 → 1.1.0 (Minor Update)
```sql
-- Безопасно: добавляем новую колонку
ALTER TABLE phoenix_kit ADD COLUMN phone varchar(20);

-- Безопасно: добавляем новый индекс
CREATE INDEX CONCURRENTLY phoenix_kit_phone_index ON phoenix_kit (phone);
```

### Версия 1.x.x → 2.0.0 (Major Update) 
```sql
-- Может содержать breaking changes
-- Пользователей предупреждаем заранее
-- Предоставляем путь миграции
```

## 🚨 Устранение проблем

### "Migration failed: permission denied"
```bash
# Убедитесь, что пользователь БД имеет права CREATE TABLE
GRANT CREATE ON SCHEMA public TO myuser;
GRANT USAGE ON SCHEMA public TO myuser;
```

### "Extension citext does not exist"
```sql
-- Выполните как суперпользователь PostgreSQL
CREATE EXTENSION IF NOT EXISTS citext;
```

### "Could not detect repository"
```bash
# Укажите репозиторий явно
mix phoenix_kit.migrate --repo MyApp.Repo
```

### Откат к предыдущей версии
```bash
# В будущих версиях будет поддерживаться
mix phoenix_kit.migrate --rollback 1.0.0
```

## 🔮 Планы развития

### v1.1 (ближайшая версия)
- [ ] Поддержка rollback миграций
- [ ] Валидация целостности данных  
- [ ] Экспорт/импорт схемы

### v2.0 (будущая версия)
- [ ] Многотенантность (разные префиксы таблиц)
- [ ] Кастомные поля пользователей
- [ ] Интеграция с существующими users таблицами

## 📚 API Reference

### PhoenixKit.SchemaMigrations

```elixir
# Получить установленную версию схемы
PhoenixKit.SchemaMigrations.get_installed_version(repo)
#=> "1.0.0" | nil

# Получить целевую версию (из библиотеки)
PhoenixKit.SchemaMigrations.get_target_version()
#=> "1.0.0"

# Проверить, нужна ли миграция
PhoenixKit.SchemaMigrations.migration_required?(repo)
#=> true | false

# Выполнить миграцию к текущей версии
PhoenixKit.SchemaMigrations.migrate_to_current(repo)
#=> :ok | {:error, reason}
```

## 💡 Best Practices

### Production Deployment
1. **Тестируйте на staging** - всегда тестируйте миграции на staging
2. **Делайте бэкапы** - создавайте резервные копии перед миграциями  
3. **Мониторинг** - следите за логами во время миграции
4. **Maintenance window** - выполняйте в окно обслуживания если нужно

### Development Workflow
1. **Обновите зависимости** - `mix deps.get`
2. **Проверьте статус** - `mix phoenix_kit.migrate --status`
3. **Примените миграцию** - автоматически или вручную
4. **Тестируйте** - убедитесь что всё работает

---

**Эта система гарантирует безопасное обновление PhoenixKit без потери данных пользователей! 🚀**