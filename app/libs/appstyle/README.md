# AppStyle — Custom Qt Quick Controls Style

A custom Qt Quick Controls 2 style module extracted from the visual branding of
[crowell.dev](https://www.crowell.dev). Uses the site's **arcane** (teal accent)
and **circuit** (neutral gray) palettes with full light/dark mode support.

## Architecture

```
qml/
├── theme/
│   └── Theme.qml          # Singleton — all color/font/spacing tokens
├── AppStyle/
│   ├── Button.qml          # Custom control templates
│   ├── CheckBox.qml
│   ├── ComboBox.qml
│   ├── MenuItem.qml
│   ├── ProgressBar.qml
│   ├── ScrollBar.qml
│   ├── Slider.qml
│   ├── Switch.qml
│   ├── TabButton.qml
│   ├── TextField.qml
│   └── ToolTip.qml
tools/
├── crowell-palette.json     # Extracted palette (source of truth)
├── extract-crowell-palette.js
└── validate-contrast.js
```

## How the Style Is Selected

The style is set in `src/main.cpp` before the QML engine loads:

```cpp
QQuickStyle::setStyle("AppStyle");
QQuickStyle::setFallbackStyle("Basic");
```

**Basic** is the fallback — any controls not overridden in AppStyle will use
Basic's implementation.

## Re-running the Palette Extractor

```bash
node tools/extract-crowell-palette.js
```

This fetches CSS from crowell.dev, parses `--color-arcane-*` and
`--color-circuit-*` custom properties, derives semantic tokens, validates
contrast ratios, and writes `tools/crowell-palette.json`.

Then validate accessibility:

```bash
node tools/validate-contrast.js
```

After updating the JSON, manually update `qml/theme/Theme.qml` with any
changed hex values.

## Adding More Controls to AppStyle

1. Create `qml/AppStyle/ControlName.qml`
2. Use `import QtQuick.Templates as T` and extend `T.ControlName`
3. Use `import AppTheme` and reference `Theme.*` for all colors/metrics
4. Add the file to `CMakeLists.txt` under the `appstyle` QML module's `QML_FILES`
5. Rebuild

## Theme Token Reference

| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| `background` | `#0a0a0c` | `#f4f4f5` | App/page background |
| `surface` | `#141416` | `#ffffff` | Cards, controls |
| `surface2` | `#1c1c1e` | `#e4e4e7` | Elevated surfaces |
| `primary` | `#40e0d0` | `#2eb8a8` | Accent, links, active |
| `secondary` | `#2eb8a8` | `#207068` | Secondary accent |
| `text` | `#e4e4e7` | `#141416` | Primary text |
| `mutedText` | `#a1a1aa` | `#52525b` | Secondary text |
| `border` | `#27272a` | `#d4d4d8` | Borders, dividers |
| `onPrimary` | `#081a19` | `#e6fffc` | Text on primary bg |
| `success` | `#4ade80` | `#16a34a` | Success state |
| `warning` | `#facc15` | `#ca8a04` | Warning state |
| `danger` | `#f87171` | `#dc2626` | Error/danger state |

## Contrast Ratios (Dark Mode)

All extracted anchor colors pass WCAG AAA (≥ 7:1):

| Pair | Ratio |
|------|-------|
| text on background | 15.3:1 |
| mutedText on background | 7.9:1 |
| text on surface | 14.7:1 |
| primary on background | 11.3:1 |
| onPrimary on primary | 10.3:1 |

No derived tokens needed adjustment.
