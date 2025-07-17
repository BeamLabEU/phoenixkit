# PhoenixKit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Elixir Version](https://img.shields.io/badge/elixir-%3E%3D%201.16-blue.svg)](https://elixir-lang.org/)
[![Phoenix Version](https://img.shields.io/badge/phoenix-%3E%3D%201.8-orange.svg)](https://phoenixframework.org/)

**PhoenixKit** is a powerful extension library for Phoenix Framework, providing ready-to-use components, utilities, and tools for rapid development of modern web applications.

🇷🇺 [Русская версия документации](README_RU.md)

## 🚀 What's New in v0.3.0

### ✨ Complete Architectural Overhaul:
- 🔥 **Full Architecture Rewrite** - from simple component to complete system
- 📊 **Interactive Dashboards** - static and LiveView dashboards
- 🎨 **Component System** - catalog of ready-to-use UI elements
- 🛠️ **Developer Utilities** - 100+ helpful functions
- 🔐 **Security** - built-in authentication and authorization
- 📈 **Telemetry** - metrics collection and monitoring
- 🌓 **Modern Design** - daisyUI + Tailwind CSS

### 🔄 Migration from v0.2.x:
- ⚠️ **Breaking changes** - complete API overhaul
- 🗑️ **Removed static component** `PhoenixKit.welcome/1`
- 🆕 **New routing** - `PhoenixKit.routes()` instead of old macros
- 📖 **Migration guide** - detailed instructions below

## ✨ Features

- 🚀 **Ready-to-use pages** - main, dashboard, components, utilities
- 📊 **Interactive dashboard** - real-time system monitoring
- ⚡ **LiveView components** - dynamic interfaces
- 🔧 **Developer utilities** - helpful functions for daily work
- 🔐 **Security system** - built-in Plugs for authentication
- 📈 **Telemetry** - metrics collection and analytics
- 🎨 **Modern design** - daisyUI + Tailwind CSS
- 📱 **Responsive interface** - adaptive components

## 🚀 Quick Start

### Installation with Igniter (Recommended)

```bash
# Automatic installation
mix igniter.install phoenix_kit
```

### Manual Installation

```elixir
# 1. Add to mix.exs
defp deps do
  [
    {:phoenix_kit, "~> 0.3.0"}
  ]
end
```

```elixir
# 2. Add to router.ex
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
# 3. Install dependencies
mix deps.get

# 4. Start server
mix phx.server
```

## 📖 Structure and Functionality

### 🏠 Main Page (`/phoenix_kit`)
Overview of all available PhoenixKit features with interactive examples and statistics.

**Features:**
- 📈 System statistics
- 🎯 Quick links to sections
- 🎨 Modern design with daisyUI
- 📱 Responsive interface

### 📊 Dashboard (`/phoenix_kit/dashboard`)
Static dashboard with system metrics and application information.

**Metrics:**
- 💾 Memory usage
- ⚡ Process count
- 🕐 Response time
- 📊 Request statistics
- 🔄 System information

### ⚡ LiveView Dashboard (`/phoenix_kit/live`)
Interactive real-time dashboard with automatic updates.

**Features:**
- 🔄 Metrics update every 5 seconds
- 📊 Interactive charts
- 🔔 Notification system
- ⚙️ Configurable alerts

### 📈 Statistics (`/phoenix_kit/live/stats`)
Detailed system analytics with extended metrics.

**Analytics:**
- 🚀 Application performance
- 💻 Resource usage
- 🌐 Network activity
- 🔍 Process analysis

### 🖥️ Monitoring (`/phoenix_kit/live/monitor`)
Monitoring system with alerts and notifications.

**Features:**
- ❤️ System health
- 🚨 Alert management
- ⚙️ Threshold configuration
- 🔔 Real-time notifications

### 🎨 Components (`/phoenix_kit/components`)
Catalog of ready-to-use UI components for your projects.

**Components:**
- 🚨 Alert components
- 🔘 Buttons and forms
- 📋 Cards and layouts
- 🪟 Modal windows
- 📊 Data tables

### 🛠️ Utilities (`/phoenix_kit/utilities`)
Collection of 100+ useful functions for development.

**Categories:**
- 📅 Date formatting
- 🔤 String processing
- ✅ Data validation
- 📂 File handling
- 🔧 Development tools

## 🔧 Using Utilities

```elixir
# Import utilities in your module
import PhoenixKit.Utils

def my_function do
  # Date formatting
  formatted_date = format_date(Date.utc_today())
  
  # Email validation
  is_valid = validate_email("user@example.com")
  
  # Text truncation
  short_text = truncate("Very long text...", 10)
  
  # Slug creation
  url_slug = slug("Hello World!")
  
  # Caching
  cached_data = cache_get_or_set("key", 3600, fn ->
    expensive_operation()
  end)
  
  # Benchmarking
  {result, time} = benchmark(fn ->
    some_operation()
  end)
  
  IO.puts("Operation took #{time}ms")
end
```

## 🔐 Security Configuration

```elixir
# In your router.ex
scope "/phoenix_kit", PhoenixKit do
  pipe_through :browser
  
  # Add authentication
  plug PhoenixKit.Plugs.AuthPlug,
    basic_auth: [username: "admin", password: "secret"],
    allowed_ips: ["127.0.0.1", "::1"]
  
  # PhoenixKit routes
  get "/", PageController, :index
  get "/dashboard", DashboardController, :index
  # ... other routes
end
```

## 📊 Telemetry

```elixir
# In your endpoint.ex
defmodule YourAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :your_app

  # Add telemetry
  plug PhoenixKit.Plugs.TelemetryPlug,
    sample_rate: 0.1,
    exclude_paths: ["/health", "/metrics"]

  # ... other plugs
end
```

## ⚙️ Configuration

```elixir
# config/config.exs
config :phoenix_kit, PhoenixKit,
  # Basic settings
  enable_dashboard: true,
  enable_live_view: true,
  auto_refresh_interval: 30_000,
  
  # Security
  require_authentication: true,
  allowed_ips: ["127.0.0.1", "::1"],
  
  # Telemetry
  telemetry_enabled: true,
  telemetry_sample_rate: 1.0,
  
  # Themes
  theme: :default,
  custom_css: false
```

## 🔄 Migration from v0.2.x

### ⚠️ Important Changes:

1. **Removed static component**
```elixir
# ❌ No longer works
<PhoenixKit.welcome title="Hello" />

# ✅ Use instead
# Navigate to /phoenix_kit for welcome page
```

2. **New routing**
```elixir
# ❌ Old way
import PhoenixKit.Router
phoenix_kit_routes()

# ✅ New way
import PhoenixKit
PhoenixKit.routes()
```

3. **New URLs**
```
# Old URLs (no longer work)
/phoenix-kit          ❌
/phoenix-kit/dashboard ❌

# New URLs
/phoenix_kit           ✅
/phoenix_kit/dashboard ✅
/phoenix_kit/live      ✅
/phoenix_kit/components ✅
/phoenix_kit/utilities  ✅
```

### 📋 Step-by-step Migration:

1. **Update dependency**
```elixir
# mix.exs
{:phoenix_kit, "~> 0.3.0"}
```

2. **Update router**
```elixir
# router.ex
import PhoenixKit  # Instead of PhoenixKit.Router
PhoenixKit.routes()  # Instead of phoenix_kit_routes()
```

3. **Remove old components**
```elixir
# Remove all usage of
<PhoenixKit.welcome title="..." />
```

4. **Update configuration**
```elixir
# config/config.exs
config :phoenix_kit, PhoenixKit,
  enable_dashboard: true,
  enable_live_view: true
```

5. **Test new functionality**
```bash
mix phx.server
# Open http://localhost:4000/phoenix_kit
```

## 🎯 Architecture v0.3.0

```
phoenixkit/
├── lib/
│   ├── phoenix_kit.ex              # Main module + routing
│   ├── phoenix_kit/
│   │   ├── controllers/            # 4 controllers
│   │   │   ├── page_controller.ex      # Main page
│   │   │   ├── dashboard_controller.ex # Dashboard
│   │   │   ├── components_controller.ex # Components
│   │   │   └── utilities_controller.ex # Utilities
│   │   ├── controllers/            # HTML templates
│   │   │   ├── page_html.ex
│   │   │   ├── dashboard_html.ex
│   │   │   ├── components_html.ex
│   │   │   └── utilities_html.ex
│   │   ├── live/                   # LiveView components
│   │   │   ├── dashboard_live.ex       # Main Live dashboard
│   │   │   ├── stats_live.ex           # Statistics
│   │   │   └── monitor_live.ex         # Monitoring
│   │   ├── plugs/                  # Middleware
│   │   │   ├── auth_plug.ex            # Authentication
│   │   │   └── telemetry_plug.ex       # Telemetry
│   │   └── utils.ex                # 100+ utilities
│   └── mix/
│       └── tasks/
│           └── phoenix_kit.install.ex  # Igniter tasks
├── test/                           # Full testing
├── priv/
│   └── static/                     # Static CSS/JS files
└── mix.exs                         # Project configuration
```

## 🔧 Requirements

- **Elixir** >= 1.16
- **Phoenix** >= 1.8
- **Phoenix LiveView** >= 1.0
- **Tailwind CSS** (for styles)
- **daisyUI** (for components)

## 🧪 Testing

```bash
# All tests
mix test

# Tests with coverage
mix test --cover

# Specific test
mix test test/phoenix_kit_test.exs

# Linters
mix credo --strict
mix dialyzer
mix format
```

## 📊 Monitoring and Metrics

PhoenixKit automatically collects metrics:

- **Performance**: response time, throughput
- **Resources**: memory, CPU, disk usage
- **Network**: incoming/outgoing traffic
- **Application**: process count, errors

Access metrics:
- 🌐 Web interface: `/phoenix_kit/dashboard`
- ⚡ Live dashboard: `/phoenix_kit/live`
- 📊 Statistics: `/phoenix_kit/live/stats`
- 📈 Monitoring: `/phoenix_kit/live/monitor`

## 🎨 Customization

```elixir
# Create custom theme
config :phoenix_kit, PhoenixKit,
  theme: :custom,
  custom_css: """
  .phoenix-kit-container {
    background: #1a1a1a;
    color: #ffffff;
  }
  """
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Phoenix Framework for the excellent foundation
- Elixir community for support
- daisyUI for beautiful components
- All project contributors

## 📞 Support

- 🐛 **Bugs**: [GitHub Issues](https://github.com/BeamLabEU/phoenixkit/issues)
- 💡 **Ideas**: [GitHub Discussions](https://github.com/BeamLabEU/phoenixkit/discussions)
- 📧 **Email**: support@beamlab.eu
- 💬 **Chat**: [Elixir Slack](https://elixir-slackin.herokuapp.com/) - #phoenix-kit

## 🗺️ Roadmap

### v0.4.0 (Planned)
- [ ] Plugin system
- [ ] GraphQL support
- [ ] Advanced analytics
- [ ] Mobile components

### v1.0.0 (Planned)
- [ ] Stable API
- [ ] Production-ready
- [ ] Complete documentation
- [ ] Enterprise support

---

**Made with ❤️ by [BeamLab EU](https://beamlab.eu)**