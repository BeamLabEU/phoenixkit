# DaisyUI 5 Migration Guide for PhoenixKit

## Overview

This guide helps you migrate from PhoenixKit's legacy theme system to the modern daisyUI 5 integration with 35+ themes, theme-controller support, and Tailwind CSS 4 compatibility.

## Quick Migration

Run the automated migration tool:

```bash
mix phoenix_kit.migrate_to_daisyui5
```

For dry-run preview:
```bash
mix phoenix_kit.migrate_to_daisyui5 --dry-run
```

## What's New in DaisyUI 5 Integration

### 🎨 35+ Professional Themes
- **Light themes**: `light`, `corporate`, `emerald`, `fantasy`, `lofi`, `pastel`, `cmyk`, `autumn`, `acid`, `lemonade`, `winter`
- **Dark themes**: `dark`, `luxury`, `business`, `night`, `coffee`, `dim`, `sunset`, `dracula`
- **Colorful themes**: `cupcake`, `retro`, `cyberpunk`, `valentine`, `halloween`, `garden`, `forest`, `aqua`, `wireframe`, `black`, `synthwave`

### ⚡ Modern CSS Architecture
- `@plugin` directives for Tailwind CSS 4 compatibility
- OKLCH color format support
- CSS custom properties with semantic naming
- Performance-optimized with RAF and debouncing

### 🎛️ Theme Controller Integration
- Automatic theme switching with data-theme attribute
- System preference detection (prefers-color-scheme)
- Persistent theme storage (localStorage/sessionStorage/cookie)
- Enhanced accessibility with proper ARIA attributes

## Manual Migration Steps

### 1. Update Theme Configuration

**Before (Legacy)**:
```elixir
config :phoenix_kit,
  theme: %{
    mode: :auto,
    primary_color: "#3b82f6",
    storage: :local_storage
  }
```

**After (DaisyUI 5)**:
```elixir
config :phoenix_kit,
  theme: %{
    theme: "auto",                   # Default theme or specific theme name
    primary_color: "#3b82f6",       # OKLCH format supported
    storage: :local_storage,
    theme_controller: true,         # Enable theme-controller
    categories: [:light, :dark, :colorful]  # Theme categories
  }
```

### 2. Update Assets

**CSS Integration**:
```html
<!-- Replace old CSS -->
<!-- <link rel="stylesheet" href="/assets/phoenix_kit.css"> -->

<!-- Add new daisyUI 5 CSS -->
<link rel="stylesheet" href="/assets/phoenix_kit_daisyui5.css">
```

**JavaScript Integration**:
```html
<!-- Replace old JS -->
<!-- <script src="/assets/phoenix_kit.js"></script> -->

<!-- Add new theme controller JS -->
<script src="/assets/phoenix_kit_daisyui5.js"></script>
```

### 3. Update Tailwind Configuration

**For Tailwind CSS 3** (tailwind.config.js):
```javascript
module.exports = {
  content: [
    "./lib/**/*.{ex,exs,heex}",
    "./deps/phoenix_kit/**/*.{ex,exs,heex}"
  ],
  theme: {
    extend: {}
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("daisyui")
  ],
  daisyui: {
    themes: [
      "light", "dark", "cupcake", "bumblebee", "emerald", "corporate",
      "synthwave", "retro", "cyberpunk", "valentine", "halloween", "garden",
      "forest", "aqua", "lofi", "pastel", "fantasy", "wireframe", "black",
      "luxury", "dracula", "cmyk", "autumn", "business", "acid", "lemonade",
      "night", "coffee", "winter", "dim", "nord", "sunset"
    ],
    darkTheme: "dark",
    base: true,
    styled: true,
    utils: true,
    prefix: "",
    logs: true,
    themeRoot: ":root"
  }
}
```

**For Tailwind CSS 4** (@config):
```css
@config "tailwind.config.js";
@plugin "@tailwindcss/forms";
@plugin "daisyui" theme({
  themes: [
    "light", "dark", "cupcake", "corporate", "synthwave", "retro"
  ]
});
```

### 4. Update Components

The theme_switcher component automatically uses the new system. If you have custom theme switching logic, update it to use `data-theme` attributes:

```javascript
// Old approach
document.documentElement.setAttribute('data-theme', 'dark');

// New approach (handled automatically by theme controller)
PhoenixKit.ThemeController.setTheme('dracula');
```

## Advanced Configuration

### Custom Theme Categories

```elixir
config :phoenix_kit,
  theme: %{
    categories: [
      light: ["light", "corporate", "emerald", "fantasy"],
      dark: ["dark", "luxury", "business", "night"],
      colorful: ["cupcake", "synthwave", "cyberpunk", "valentine"]
    ]
  }
```

### OKLCH Color Integration

```elixir
config :phoenix_kit,
  theme: %{
    primary_color: "oklch(0.7 0.15 200)",  # Modern OKLCH format
    custom_colors: %{
      brand: "oklch(0.6 0.2 250)",
      accent: "oklch(0.8 0.1 150)"
    }
  }
```

### Storage Options

```elixir
config :phoenix_kit,
  theme: %{
    storage: :local_storage,  # Persistent across sessions
    # storage: :session,      # Session only
    # storage: :cookie,       # Cookie-based (requires Phoenix session)
  }
```

## Troubleshooting

### Common Issues

1. **Themes not applying**: Check that `data-theme` attribute is set on `<html>` element
2. **JavaScript errors**: Ensure daisyUI 5 JS is loaded after Phoenix LiveView
3. **CSS conflicts**: Remove old phoenix_kit.css references
4. **Build errors**: Update Tailwind config for daisyUI 5 plugin syntax

### Debug Mode

Enable debug logging:
```elixir
config :phoenix_kit, debug_themes: true
```

### Verification

After migration, test:
1. Theme switching works in UI
2. Themes persist across page reloads  
3. System theme preference is respected
4. All 35+ themes render correctly

## Support

- Run `mix phoenix_kit.migrate_to_daisyui5 --help` for all options
- Check generated documentation in `docs/daisyui_5_integration.md`
- Review example configurations in `priv/static/examples/`

## Migration Checklist

- [ ] Run migration tool: `mix phoenix_kit.migrate_to_daisyui5`
- [ ] Update asset references (CSS/JS)
- [ ] Test theme switching functionality
- [ ] Verify theme persistence
- [ ] Update parent app Tailwind config
- [ ] Test all target themes
- [ ] Remove legacy theme system references
- [ ] Update documentation/comments