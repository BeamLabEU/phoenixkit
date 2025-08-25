# PhoenixKit Theme System Architecture

## Overview

PhoenixKit implements a modern, library-first theme system built on daisyUI 5 with comprehensive theme controller integration. The architecture is designed for parent application integration without circular dependencies.

## Core Components

### 1. Configuration Layer (`PhoenixKit.ThemeConfig`)

**Purpose**: Centralized theme configuration with parent application integration

**Key Functions**:
- `get_all_daisyui_themes/0` - Returns all 35+ available themes
- `modern_css_variables/0` - Provides OKLCH-compatible CSS variables
- `theme_controller_enabled?/0` - Checks theme controller activation
- `parent_app_config/0` - Parent application theme overrides

**Theme Categories**:
```elixir
%{
  light: ["light", "corporate", "emerald", "fantasy", "lofi", "pastel", "cmyk", "autumn", "acid", "lemonade", "winter"],
  dark: ["dark", "luxury", "business", "night", "coffee", "dim", "sunset", "dracula"],  
  colorful: ["cupcake", "retro", "cyberpunk", "valentine", "halloween", "garden", "forest", "aqua", "wireframe", "black", "synthwave"]
}
```

### 2. Asset Layer

#### CSS Architecture (`phoenix_kit_daisyui5.css`)

**Modern Plugin System**:
```css
@plugin "daisyui" theme({
  themes: ["light", "dark", /* all 35+ themes */]
});
```

**OKLCH Color Support**:
```css
:root {
  --color-primary: oklch(0.7 0.15 200);
  --color-secondary: oklch(0.6 0.1 250);
  --color-accent: oklch(0.8 0.12 150);
}
```

**Component Styles**:
- Form integration with daisyUI classes
- Button variants with theme-aware colors
- Layout utilities with responsive design
- Accessibility enhancements

#### JavaScript Architecture (`phoenix_kit_daisyui5.js`)

**Theme Controller Class**:
```javascript
class PhoenixKitThemeController {
  constructor() {
    this.initializeThemeSystem();
    this.setupEventListeners();
    this.integrateWithPhoenixLiveView();
  }
}
```

**Performance Optimization**:
- RequestAnimationFrame for smooth transitions
- Debounced theme switching (300ms)
- Event delegation for efficient handling
- Memory leak prevention with cleanup

**Phoenix LiveView Integration**:
- Automatic theme sync on page navigation
- Custom event dispatching for theme changes
- Hook system for component reactivity

### 3. Component Layer (`core_components.ex`)

#### Theme Switcher Component

**Features**:
- Categorized theme display (Light/Dark/Colorful)
- Search and filter capabilities
- Theme preview with live updates
- Accessibility with ARIA labels
- Responsive design for all screen sizes

**Implementation**:
```elixir
def theme_switcher(assigns) do
  themes = PhoenixKit.ThemeConfig.get_all_daisyui_themes()
  categories = PhoenixKit.ThemeConfig.theme_categories()
  
  assigns = assign(assigns, themes: themes, categories: categories)
  # Component template with categorized theme selection
end
```

### 4. Migration Layer (`phoenix_kit.migrate_to_daisyui5.ex`)

**Automated Migration Features**:
- Configuration file updates
- Asset file generation
- Component integration
- Documentation generation
- Backup and rollback capabilities

**Safety Features**:
- Dry-run mode for preview
- Automatic backups before changes
- Validation of existing configurations
- Error recovery and cleanup

## Integration Patterns

### Parent Application Integration

**1. Configuration Override**:
```elixir
# Parent app config/config.exs
config :phoenix_kit,
  theme: %{
    theme: "corporate",           # Override default theme
    categories: [:light, :dark],  # Limit available themes
    storage: :cookie            # Use cookie-based persistence
  }
```

**2. Asset Integration**:
```html
<!-- Parent app layout -->
<link rel="stylesheet" href={~p"/assets/phoenix_kit_daisyui5.css"}>
<script src={~p"/assets/phoenix_kit_daisyui5.js"}></script>
```

**3. Tailwind Configuration**:
```javascript
// Parent app tailwind.config.js
module.exports = {
  content: [
    "./lib/**/*.{ex,exs,heex}",
    "./deps/phoenix_kit/**/*.{ex,exs,heex}"  // Include PhoenixKit templates
  ],
  plugins: [require("daisyui")],
  daisyui: {
    themes: PhoenixKit.ThemeConfig.get_enabled_themes()
  }
}
```

### Storage Integration

**Local Storage** (Default):
- Persistent across browser sessions
- Client-side only, no server state
- Immediate theme application

**Session Storage**:
- Per-session persistence
- Cleared on browser close
- Good for temporary theme testing

**Cookie Storage**:
- Server-side theme detection
- Phoenix session integration
- SSR theme consistency

## Performance Considerations

### CSS Optimization

**Critical CSS Inlining**:
- Theme variables inlined in `<head>`
- Deferred loading of non-critical styles
- Minimal layout shift during theme changes

**Bundle Size**:
- Tree-shaking of unused theme definitions
- Lazy loading of theme preview assets
- Compression for production builds

### JavaScript Optimization

**Efficient Event Handling**:
```javascript
// Debounced theme switching
const debouncedThemeChange = this.debounce((theme) => {
  requestAnimationFrame(() => {
    this.applyTheme(theme);
  });
}, 300);
```

**Memory Management**:
- Proper event listener cleanup
- WeakMap usage for object associations
- Garbage collection friendly patterns

## Security Considerations

### XSS Prevention

**Theme Name Validation**:
```elixir
def validate_theme_name(theme) do
  allowed_themes = get_all_daisyui_themes()
  if theme in allowed_themes, do: {:ok, theme}, else: {:error, :invalid_theme}
end
```

**Safe HTML Output**:
- All theme names escaped in templates
- No dynamic CSS injection
- CSP-compatible implementation

### CSRF Protection

**LiveView Integration**:
- Theme changes use Phoenix channels
- CSRF tokens for sensitive operations
- Session validation for theme persistence

## Testing Architecture

### Unit Tests

**Configuration Tests**:
```elixir
test "returns all daisyUI themes" do
  themes = PhoenixKit.ThemeConfig.get_all_daisyui_themes()
  assert length(themes) >= 35
  assert "light" in themes
  assert "dark" in themes
end
```

**Component Tests**:
- Theme switcher rendering
- Event handling verification
- Accessibility compliance

### Integration Tests

**End-to-End Theme Switching**:
- Browser automation with theme changes
- Visual regression testing
- Performance benchmarking

**Parent App Integration**:
- Configuration override testing
- Asset loading verification
- Build system compatibility

## Monitoring and Debugging

### Debug Mode

**Enable Debug Logging**:
```elixir
config :phoenix_kit, debug_themes: true
```

**Debug Output**:
- Theme switching events
- Configuration validation
- Performance metrics
- Error stack traces

### Production Monitoring

**Performance Metrics**:
- Theme switch latency
- Asset loading times
- Memory usage patterns
- User theme preferences

**Error Tracking**:
- Theme application failures
- JavaScript errors
- CSS parsing issues
- Storage quota exceeded

## Future Roadmap

### Planned Enhancements

1. **AI-Powered Theme Suggestions**
   - User behavior analysis
   - Automatic theme recommendations
   - Accessibility-based suggestions

2. **Advanced Customization**
   - Visual theme editor
   - Custom color palette generation
   - Brand integration tools

3. **Performance Improvements**
   - Service worker caching
   - Progressive theme loading
   - Optimized asset delivery

### Compatibility Goals

- **Tailwind CSS 4**: Full compatibility with new architecture
- **Phoenix LiveView 1.0**: Enhanced integration features
- **Accessibility Standards**: WCAG 2.2 AA compliance
- **Modern Browsers**: ES2022+ features with fallbacks