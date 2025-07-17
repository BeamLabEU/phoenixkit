# PhoenixKit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Elixir Version](https://img.shields.io/badge/elixir-%3E%3D%201.16-blue.svg)](https://elixir-lang.org/)
[![Phoenix Version](https://img.shields.io/badge/phoenix-%3E%3D%201.8-orange.svg)](https://phoenixframework.org/)

**PhoenixKit** - это мощная библиотека расширений для Phoenix Framework, предоставляющая готовые компоненты, утилиты и инструменты для быстрой разработки современных веб-приложений.

## ✨ Возможности

- 🚀 **Готовые к использованию компоненты** - Богатый набор UI компонентов
- 📊 **Интерактивная панель управления** - Мониторинг системы в реальном времени
- ⚡ **LiveView компоненты** - Динамические интерфейсы с Phoenix LiveView
- 🔧 **Утилиты разработчика** - Полезные функции для повседневной работы
- 🔐 **Система безопасности** - Встроенные Plug для аутентификации
- 📈 **Телеметрия** - Сбор метрик и аналитики
- 🎨 **Настраиваемые темы** - Гибкая система стилизации
- 📱 **Отзывчивый дизайн** - Адаптивные интерфейсы

## 🚀 Быстрый старт

### Установка с Igniter (Рекомендуется)

**PhoenixKit** использует [Igniter](https://github.com/ash-project/igniter) для безопасной установки и обновления. Это современный подход, который автоматически модифицирует ваш код без конфликтов.

#### Вариант 1: Автоматическая установка

```bash
# Одна команда для добавления зависимости и установки
mix igniter.install phoenix_kit
```

#### Вариант 2: Создание нового проекта с PhoenixKit

```bash
# Создать новый Phoenix проект с PhoenixKit
mix igniter.new my_app --install phoenix_kit --with phx.new
```

#### Вариант 3: Ручная установка

```elixir
# 1. Добавьте в mix.exs
defp deps do
  [
    {:phoenix_kit, github: "BeamLabEU/phoenixkit"}
  ]
end
```

```bash
# 2. Установите зависимости
mix deps.get

# 3. Запустите установку
mix igniter.install phoenix_kit
```

### Что происходит при установке

Igniter автоматически:
- ✅ Добавляет `import PhoenixKit` в ваш router.ex
- ✅ Добавляет `PhoenixKit.routes()` в browser scope
- ✅ Копирует статические файлы CSS/JS
- ✅ Добавляет конфигурацию в config/config.exs
- ✅ Создает примеры использования
- ✅ Проверяет совместимость с вашим проектом

### Опции установки

```bash
# Пропустить добавление маршрутов
mix igniter.install phoenix_kit --no-routes

# Пропустить копирование ассетов
mix igniter.install phoenix_kit --no-assets

# Пропустить добавление конфигурации
mix igniter.install phoenix_kit --no-config

# Пропустить создание примеров
mix igniter.install phoenix_kit --no-examples
```

### Запуск

```bash
# Запустите сервер
mix phx.server
```

### Результат

После установки PhoenixKit доступен по адресам:
- **Главная страница**: http://localhost:4000/phoenix_kit
- **Панель управления**: http://localhost:4000/phoenix_kit/dashboard
- **Live дашборд**: http://localhost:4000/phoenix_kit/live
- **Компоненты**: http://localhost:4000/phoenix_kit/components
- **Утилиты**: http://localhost:4000/phoenix_kit/utilities

## 🔄 Обновление и управление

### Обновление PhoenixKit

```bash
# Обновить до последней версии
mix igniter.upgrade phoenix_kit

# Или обновить все пакеты
mix igniter.upgrade
```

### Удаление PhoenixKit

```bash
# Полностью удалить PhoenixKit
mix phoenix_kit.uninstall

# Опции удаления
mix phoenix_kit.uninstall --keep-config     # Сохранить конфигурацию
mix phoenix_kit.uninstall --keep-assets     # Сохранить ассеты
mix phoenix_kit.uninstall --remove-dependency # Удалить из mix.exs
```

### Альтернативная установка (без Igniter)

Если вы предпочитаете ручную установку:

```elixir
# 1. Добавьте в mix.exs
defp deps do
  [
    {:phoenix_kit, github: "BeamLabEU/phoenixkit"}
  ]
end
```

```elixir
# 2. Добавьте в router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import PhoenixKit

  scope "/" do
    pipe_through :browser
    
    get "/", YourAppWeb.PageController, :index
    PhoenixKit.routes()
  end
end
```

```bash
# 3. Получите зависимости
mix deps.get

# 4. Запустите сервер
mix phx.server
```

## 📖 Документация

### Основные компоненты

#### 1. Главная страница (`/phoenix_kit`)
Обзор всех доступных функций PhoenixKit с интерактивными примерами.

#### 2. Панель управления (`/phoenix_kit/dashboard`)
Статический дашборд с системными метриками:
- Использование памяти
- Количество процессов
- Время отклика
- Статистика запросов

#### 3. Live Dashboard (`/phoenix_kit/live`)
Интерактивный дашборд в реальном времени:
- Обновление метрик каждые 5 секунд
- Интерактивные графики
- Система уведомлений
- Настраиваемые алерты

#### 4. Статистика (`/phoenix_kit/live/stats`)
Детальная аналитика системы:
- Производительность
- Использование ресурсов
- Сетевая активность
- Анализ процессов

#### 5. Мониторинг (`/phoenix_kit/live/monitor`)
Система мониторинга с алертами:
- Здоровье системы
- Управление алертами
- Настройка пороговых значений
- Уведомления в реальном времени

#### 6. Компоненты (`/phoenix_kit/components`)
Каталог готовых UI компонентов:
- Alert компоненты
- Кнопки и формы
- Карточки и макеты
- Модальные окна
- Таблицы данных

#### 7. Утилиты (`/phoenix_kit/utilities`)
Коллекция полезных функций:
- Форматирование дат
- Обработка строк
- Валидация данных
- Работа с файлами
- Инструменты разработки

### Использование утилит

```elixir
# Импортируйте утилиты в ваш контроллер
import PhoenixKit.Utils

def index(conn, _params) do
  # Форматирование дат
  formatted_date = format_date(Date.utc_today())
  
  # Проверка email
  is_valid = validate_email("user@example.com")
  
  # Обрезка текста
  short_text = truncate("Very long text...", 10)
  
  # Создание slug
  url_slug = slug("Hello World!")
  
  # Кеширование
  cached_data = cache_get_or_set("key", 3600, fn ->
    expensive_operation()
  end)
  
  render(conn, :index, data: cached_data)
end
```

### Настройка безопасности

Добавьте аутентификацию к PhoenixKit endpoints:

```elixir
# В вашем router.ex
scope "/phoenix_kit", PhoenixKit do
  pipe_through :browser
  
  # Добавьте аутентификацию
  plug PhoenixKit.Plugs.AuthPlug,
    basic_auth: [username: "admin", password: "secret"],
    allowed_ips: ["127.0.0.1", "::1"]
  
  # Маршруты PhoenixKit
  get "/", PageController, :index
  # ... остальные маршруты
end
```

### Телеметрия

Включите сбор метрик:

```elixir
# В вашем endpoint.ex
defmodule YourAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :your_app

  # Добавьте телеметрию
  plug PhoenixKit.Plugs.TelemetryPlug,
    sample_rate: 0.1,
    exclude_paths: ["/health", "/metrics"]

  # ... остальные plugs
end
```

## ⚙️ Конфигурация

Настройте PhoenixKit в `config/config.exs`:

```elixir
config :phoenix_kit, PhoenixKit,
  # Основные настройки
  enable_dashboard: true,
  enable_live_view: true,
  auto_refresh_interval: 30_000,
  
  # Новые опции (добавлены автоматически при установке через Igniter)
  enable_telemetry: true,
  enable_security: true,
  theme: :default,
  cache_enabled: true,
  
  # Настройки безопасности
  require_authentication: true,
  allowed_ips: ["127.0.0.1", "::1"],
  
  # Телеметрия
  telemetry_enabled: true,
  telemetry_sample_rate: 1.0,
  
  # Темы
  custom_css: false
```

> **Примечание**: При использовании Igniter конфигурация добавляется автоматически. При обновлении PhoenixKit новые опции добавляются без перезаписи ваших настроек.

## 🎯 Структура проекта

```
phoenixkit/
├── lib/
│   ├── phoenix_kit.ex              # Основной модуль
│   ├── phoenix_kit/
│   │   ├── controllers/            # Контроллеры
│   │   │   ├── page_controller.ex
│   │   │   ├── dashboard_controller.ex
│   │   │   ├── components_controller.ex
│   │   │   └── utilities_controller.ex
│   │   ├── live/                   # LiveView компоненты
│   │   │   ├── dashboard_live.ex
│   │   │   ├── stats_live.ex
│   │   │   └── monitor_live.ex
│   │   ├── plugs/                  # Middleware
│   │   │   ├── auth_plug.ex
│   │   │   └── telemetry_plug.ex
│   │   └── utils.ex                # Утилиты
│   └── mix/
│       └── tasks/
│           └── phoenix_kit.install.ex
├── test/                           # Тесты
├── priv/
│   └── static/                     # Статические файлы
└── mix.exs                         # Конфигурация проекта
```

## 🔧 Разработка

### Требования

- Elixir >= 1.16
- Phoenix >= 1.8
- Erlang/OTP >= 26

### Запуск в режиме разработки

```bash
# Клонирование репозитория
git clone https://github.com/BeamLabEU/phoenixkit.git
cd phoenixkit

# Установка зависимостей
mix deps.get

# Запуск тестов
mix test

# Генерация документации
mix docs
```

### Запуск линтеров

```bash
# Credo
mix credo --strict

# Dialyzer
mix dialyzer

# Форматирование кода
mix format
```

## 🧪 Тестирование

Запустите тесты:

```bash
# Все тесты
mix test

# Тесты с покрытием
mix test --cover

# Конкретный тест
mix test test/phoenix_kit_test.exs
```

## 📊 Мониторинг и метрики

PhoenixKit автоматически собирает следующие метрики:

- **Производительность**: время отклика, пропускная способность
- **Ресурсы**: использование памяти, CPU, диска
- **Сеть**: входящий/исходящий трафик, подключения
- **Приложение**: количество процессов, ошибки, успешность

Метрики доступны через:
- Web интерфейс в дашборде
- API эндпоинты (`/phoenix_kit/api/stats`)
- Telemetry события

## 🎨 Кастомизация

### Темы

Создайте собственную тему:

```elixir
# config/config.exs
config :phoenix_kit, PhoenixKit,
  theme: :custom,
  custom_css: """
  .phoenix-kit-container {
    background: #1a1a1a;
    color: #ffffff;
  }
  """
```

### Компоненты

Переопределите компоненты:

```elixir
# В вашем приложении
defmodule YourAppWeb.CustomPhoenixKitComponents do
  use Phoenix.Component
  
  def custom_alert(assigns) do
    ~H"""
    <div class="custom-alert">
      <%= @message %>
    </div>
    """
  end
end
```

## 🔌 Интеграции

### Prometheus

```elixir
# Экспорт метрик в Prometheus
config :phoenix_kit, PhoenixKit,
  prometheus_enabled: true,
  metrics_endpoint: "/metrics"
```

### Grafana

Импортируйте готовые дашборды Grafana из папки `grafana/`.

### Datadog

```elixir
# Отправка метрик в Datadog
config :phoenix_kit, PhoenixKit,
  datadog_enabled: true,
  datadog_api_key: System.get_env("DATADOG_API_KEY")
```

## 📈 Производительность

### Оптимизация

- Используйте `sample_rate` для уменьшения нагрузки телеметрии
- Настройте `exclude_paths` для исключения ненужных endpoints
- Включите кеширование для часто используемых данных

### Мониторинг производительности

```elixir
# Benchmark утилиты
{result, time} = PhoenixKit.Utils.benchmark(fn ->
  expensive_operation()
end)

IO.puts("Operation took #{time}ms")
```

## 🛡️ Безопасность

### Аутентификация

- Basic HTTP аутентификация
- IP whitelist
- Кастомные функции аутентификации

### Лучшие практики

- Всегда используйте HTTPS в продакшене
- Ограничьте доступ к дашборду
- Регулярно обновляйте зависимости
- Мониторьте подозрительную активность

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие PhoenixKit!

1. Форкните репозиторий
2. Создайте ветку для новой функции (`git checkout -b feature/amazing-feature`)
3. Сделайте коммит изменений (`git commit -m 'Add amazing feature'`)
4. Отправьте изменения в ветку (`git push origin feature/amazing-feature`)
5. Создайте Pull Request

### Рекомендации

- Следуйте существующему стилю кода
- Добавляйте тесты для новых функций
- Обновляйте документацию
- Проверяйте работоспособность с помощью `mix test`

## 📄 Лицензия

Этот проект лицензирован под MIT License - подробности в файле [LICENSE](LICENSE).

## 🙏 Благодарности

- Phoenix Framework за отличную основу
- Elixir сообщество за поддержку
- Всем контрибьюторам проекта

## 📞 Поддержка

- 🐛 **Баги**: [GitHub Issues](https://github.com/BeamLabEU/phoenixkit/issues)
- 💡 **Идеи**: [GitHub Discussions](https://github.com/BeamLabEU/phoenixkit/discussions)
- 📧 **Email**: support@beamlab.eu
- 💬 **Чат**: [Elixir Slack](https://elixir-slackin.herokuapp.com/) - #phoenix-kit

## 🗺️ Roadmap

### v0.2.0 (Планируется)
- [ ] Система плагинов
- [ ] GraphQL поддержка
- [ ] Расширенная аналитика
- [ ] Мобильные компоненты

### v0.3.0 (Планируется)
- [ ] Microservices мониторинг
- [ ] Kubernetes интеграция
- [ ] Machine Learning метрики
- [ ] Advanced alerting

### v1.0.0 (Планируется)
- [ ] Stable API
- [ ] Production-ready
- [ ] Полная документация
- [ ] Enterprise поддержка

---

**Сделано с ❤️ командой [BeamLab EU]**