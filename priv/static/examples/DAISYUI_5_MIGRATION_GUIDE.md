# PhoenixKit Modern Theme System Guide

## Overview

PhoenixKit now uses **ONLY** daisyUI 5 + Tailwind CSS 4 architecture. 
Legacy theme systems have been completely removed for a streamlined, modern approach.

## ⚠️ Breaking Changes

- **NO backwards compatibility** with old theme systems
- **Tailwind CSS 4 required** - no support for version 3
- **@plugin directives only** - no JavaScript configuration
- **OKLCH colors only** - modern color format

## Quick Setup

This is now the **ONLY** way to integrate PhoenixKit themes:

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

**New (Modern Architecture)**:
```elixir
config :phoenix_kit,
  theme: %{
    theme: "auto",                           # Default theme
    primary_color: "oklch(55% 0.3 240)",    # OKLCH format REQUIRED  
    storage: :local_storage,
    themes: [:light, :dark, :synthwave, :dracula]  # Selected themes
  }
```

### 2. Update Assets

**CSS Integration (Tailwind CSS 4 ONLY)**:
```css
/* In your parent app's app.css */
@import "tailwindcss";
@plugin "daisyui" {
  themes: light --default, dark --prefersdark, synthwave, dracula;
};

/* Import PhoenixKit theme utilities */  
@import "./deps/phoenix_kit/priv/static/assets/phoenix_kit_daisyui5.css";
```

**Content Configuration**:
```css
/* Add PhoenixKit content paths */
@source "./lib/**/*.{ex,heex,js}";
@source "./deps/phoenix_kit/**/*.{ex,heex}";
```

### 3. Tailwind CSS 4 Required

**⚠️ BREAKING CHANGE**: Tailwind CSS 3 is no longer supported.

**Required Setup**:
```css
/* app.css - This is the ONLY supported way */
@import "tailwindcss";

@source "./lib/**/*.{ex,heex,js}";
@source "./assets/**/*.js";  
@source "./deps/phoenix_kit/**/*.{ex,heex}";

@plugin "daisyui" {
  themes: 
    light --default,
    dark --prefersdark,
    synthwave,
    dracula,
    corporate,
    luxury;
};
```

**JavaScript files are not needed** - everything is in CSS now!

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