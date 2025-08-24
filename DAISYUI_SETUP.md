# DaisyUI Setup Guide for PhoenixKit (ИСПРАВЛЕНО)

PhoenixKit uses DaisyUI for beautiful, professional styling. If you see that only some components (like primary buttons) are styled while others appear plain, this means **DaisyUI theme is not activated**.

## 🎯 Problem Diagnosis

**Symptoms:**
- ✅ Primary buttons are styled (blue background)
- ❌ Alert, Card, Stats, Secondary/Accent buttons are unstyled
- ❌ Admin dashboard looks plain
- ❌ Forms have no styling

**Root Cause:** Missing `data-theme` attribute in HTML and/or DaisyUI plugin not configured.

## 🚀 Solution

### 1. ~~Install DaisyUI~~ (НЕ НУЖНО)

~~```bash~~
~~npm install daisyui@latest~~
~~```~~

**DaisyUI уже встроен в PhoenixKit!** Не нужно устанавливать отдельно.

### 2. Create/Update tailwind.config.js

**Critical:** Create minimal config with DaisyUI plugin:

```javascript
// assets/tailwind.config.js
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/**/*.{ex,heex,js}",      // ← СКАНИРУЕТ локальные PhoenixKit файлы
    "../assets/**/*.js"
    // НЕ НУЖНО: "./deps/phoenix_kit/**/*.{ex,heex,js}" - PhoenixKit без исходников
  ],
  plugins: [
    require("./vendor/daisyui")       // ← КРИТИЧНО! Использует встроенный DaisyUI
  ]
  // НЕ НУЖНО: safelist, daisyui: {}, themes - работает без них
}
```

**ВАЖНО:** Используйте `"./vendor/daisyui"` (встроенный), НЕ `"daisyui"` (npm).

### 3. Set Theme (**КРИТИЧНО!**)

Add theme to your root layout:

```heex
<!-- В root.html.heex - БЕЗ ЭТОГО НЕ РАБОТАЕТ! -->
<html lang="en" data-theme="light">
```

**Без `data-theme` DaisyUI классы не применяют стили!**

### 4. Update Mix Config

Убедитесь, что Tailwind использует config файл:

```elixir
# config/config.exs
config :tailwind,
  version: "4.1.0",  # или новее
  zenclock: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
      --config=assets/tailwind.config.js    # ← ВАЖНО!
    ),
    cd: Path.expand("..", __DIR__)
  ]
```

### 5. Rebuild Assets

```bash
# Пересобрать с новой конфигурацией
mix assets.build
```

## ✅ Verification

After setup, visit `/phoenix_kit/daisy-test` to verify:

- ✅ `HTML data-theme: light` (не "none")
- ✅ `CSS Variables: Working ✓` (не "Missing")
- ✅ `Alert class: Working ✓`
- ✅ `Card class: Working ✓`  
- ✅ `Stats class: Working ✓`

## 🔍 Troubleshooting

### Still not working?

1. **Check data-theme:** Убедитесь, что `<html data-theme="light">` в root.html.heex
2. **Check DaisyUI plugin:** Убедитесь, что `require("./vendor/daisyui")` в plugins
3. **Check config usage:** Убедитесь, что `--config=assets/tailwind.config.js` в mix config
4. **Clear cache:** Run `mix clean && mix assets.build`
5. **Check console:** Look for TailwindCSS build errors

### ~~Alternative: Safelist approach~~ (НЕ НУЖНО)

~~Safelist не нужен~~ - PhoenixKit создает локальные файлы с DaisyUI классами, которые автоматически сканируются через `"../lib/**/*.{ex,heex,js}"`.

### ~~Content paths for deps~~ (НЕ НУЖНО)

~~`"./deps/phoenix_kit/**/*.{ex,heex,js}"` не нужно~~ - PhoenixKit устанавливается как скомпилированный hex package без исходных файлов.

## 📋 Quick Test

1. Go to `/phoenix_kit/daisy-test`
2. Click "Run Client-Side Diagnostic"  
3. Should show "Working ✓" for all components

## 🎓 Why This Works

PhoenixKit автоматически создает локальные файлы в `lib/your_app_web/phoenix_kit_live/` с DaisyUI классами. Эти файлы сканируются через стандартный content path `"../lib/**/*.{ex,heex,js}"`.

**Главное:** `data-theme` активирует CSS переменные DaisyUI!

---

**Result:** Professional, beautiful PhoenixKit interface with full DaisyUI styling! 🎨

## 📝 Summary for Quick Setup

**Минимально необходимо:**

1. `<html data-theme="light">` в root.html.heex  
2. `assets/tailwind.config.js` с `require("./vendor/daisyui")`
3. `--config=assets/tailwind.config.js` в mix config
4. `mix assets.build`

**НЕ нужно:**
- npm install daisyui
- content paths к deps/phoenix_kit
- safelist
- daisyui: {} конфигурация
- Дополнительные HTML файлы