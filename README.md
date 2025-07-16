# PhonixKit

Минимальный Phoenix компонент и LiveView для создания красивых интерактивных welcome страниц.

## Установка

Добавьте `phonix_kit` в список зависимостей в `mix.exs`:

```elixir
def deps do
  [
    {:phonix_kit, "~> 0.2.0"}
  ]
end
```

## Использование

### 1. Статичный компонент (обратная совместимость)

Используйте компонент в любом Phoenix шаблоне:

```elixir
<PhonixKit.welcome title="Добро пожаловать!" />
```

### 2. Интерактивная LiveView страница (новое в v0.2.0)

Добавьте маршруты в ваш `router.ex`:

```elixir
import PhonixKit.Router

scope "/" do
  pipe_through :browser
  
  # Добавляет маршруты: /phonix-kit, /phonix-kit/:title, /phonix-kit/:title/:subtitle
  phonix_kit_routes()
  
  # Или кастомный путь:
  # phonix_kit_routes("/welcome")
  
  # Или только основной маршрут:
  # phonix_kit_welcome_route("/welcome")
end
```

Теперь откройте `/phonix-kit` в браузере для интерактивной страницы!

## Что нового в v0.2.0

✨ **Интерактивные LiveView страницы** с:
- **Welcome страница** - счетчик в реальном времени, анимации, интерактивные кнопки
- **Dashboard страница** - простая панель управления с заголовком
- Параметрами через URL для обеих страниц
- Без JavaScript на клиенте

🔄 **Полная обратная совместимость** - старые компоненты продолжают работать

🛠 **Простая установка** - один макрос добавляет все маршруты

## Миграция с v0.1.0

### Если используете только компонент
Ничего менять не нужно! Компонент `<PhonixKit.welcome />` работает как прежде.

### Если хотите новую LiveView функциональность
1. Обновите зависимость: `mix deps.update phonix_kit`
2. Добавьте в `router.ex`:
   ```elixir
   import PhonixKit.Router
   
   scope "/" do
     pipe_through :browser
     phonix_kit_routes()
   end
   ```
3. Перезапустите сервер: `mix phx.server`
4. Откройте `/phonix-kit` или `/phonix-kit/dashboard` в браузере

## Параметры компонента

- `title` (обязательный) - заголовок страницы
- `subtitle` (опциональный) - подзаголовок, по умолчанию "Phonix Kit успешно установлен"
- `class` (опциональный) - дополнительные CSS классы

## Примеры

### Статичный компонент
```elixir
# Базовое использование
<PhonixKit.welcome title="Hello World" />

# С кастомным подзаголовком
<PhonixKit.welcome title="Мой проект" subtitle="Готов к работе!" />
```

### LiveView с параметрами через URL
```
# Welcome страница
/phonix-kit                              # базовая страница
/phonix-kit/Мой%20проект                 # кастомный заголовок
/phonix-kit/Привет/Все%20работает        # заголовок + подзаголовок

# Dashboard страница
/phonix-kit/dashboard                    # базовая dashboard страница
/phonix-kit/dashboard/Панель             # кастомный заголовок
/phonix-kit/dashboard/Админ/Управление   # заголовок + подзаголовок
```

## Возможности

- 🎨 Градиентные фоны (синий → фиолетовый для welcome, серый для dashboard)
- 📱 Адаптивный дизайн
- ⚡ LiveView интерактивность
- 🎭 Анимации и переходы
- 🔢 Интерактивный счетчик (welcome страница)
- 📊 Dashboard страница с простым заголовком
- 🌐 Параметры через URL для обеих страниц
- 💎 Tailwind CSS стили

## Требования

- Phoenix LiveView ~> 0.18 или ~> 1.0.0-rc
- Tailwind CSS (для стилей)

## Лицензия

MIT