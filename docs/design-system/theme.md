# PigeonFly — Design System / Theme

> The brand theme for the mobile app. High-fidelity reference: [`../wireframes/ui-high-fidelity.html`](../wireframes/ui-high-fidelity.html).
> The whole app is themed from **design tokens** — change a token, re-skin everything. Built global-first (LTR + RTL).
> **Last updated:** 2026-10-03 · **Version:** 1.0

---

## 1. Brand

- **Direction:** clean, modern, trustworthy — a competitive *flight* product. Sky blue = flight; gold = winning/ranking.
- **Logo mark:** trophy / pigeon in a rounded-square on the brand gradient.

## 2. Color tokens

| Token | Hex | Use |
|-------|-----|-----|
| `brand` | `#0B74D1` | primary actions, active states, links |
| `brand-d` | `#0A5DA8` | pressed / gradient end |
| `brand-l` | `#3D93DD` | gradient mid |
| `brand-50` | `#EAF4FD` | tinted backgrounds, icon chips |
| `brand-100` | `#D4E8FB` | borders on tinted surfaces |
| `gold` | `#F4A825` | rank/medal accents, "pigeon count" chips |
| `gold-50` | `#FEF4E1` | gold chip background |
| `ink` | `#0F172A` | primary text, dark cards |
| `ink-2` | `#334155` | secondary text |
| `sub` | `#64748B` | tertiary text / captions |
| `mut` | `#94A3B8` | placeholder / disabled |
| `line` | `#E7ECF2` | borders / dividers |
| `soft` | `#F3F6FA` | input + segmented backgrounds |
| `bg` | `#E9EEF4` | app background |
| `card` | `#FFFFFF` | surfaces |
| `ok` | `#16A34A` | live / success |
| `danger` | `#E23D3D` | report / destructive |

**Gradients:** `brand → sky` (`135deg #0B74D1 → #57ABE7`) for hero/login; `dusk` for alternate tournament covers.

## 3. Typography

| Role | Font | Weight | Size |
|------|------|--------|------|
| Display / screen titles | **Plus Jakarta Sans** | 800 | 21–30 |
| Titles / card headings | **Inter** | 700 | 15–17 |
| Body | Inter | 400 / 600 | 13–14 |
| Caption / meta | Inter | 500 / 600 | 10–12 |
| Numbers (averages, counts) | Plus Jakarta Sans | 800 | emphasised |

> Flutter: `google_fonts` — `Inter` as the base text theme, `Plus Jakarta Sans` for display/number styles.

## 4. Shape & elevation

- **Radius:** cards `20px`, sheets `22px`, buttons `14px`, chips `9–11px`, avatars full.
- **Shadow (sm):** `0 2px 10px rgba(15,23,42,.07)` — cards.
- **Shadow (lg):** `0 12px 34px rgba(15,23,42,.14)` — floating / phone.
- **Primary button shadow:** `0 8px 18px rgba(11,116,209,.32)`.

## 5. Core components

| Component | Notes |
|-----------|-------|
| Bottom nav | 5 slots: Tournaments · Posts · **＋ (center FAB, gradient)** · Records · Profile |
| Tournament card | gradient cover, LIVE pill (top-left), Avg badge (top-right), chips, like/view/owner footer |
| Day tabs | pill tabs, active = brand gradient; label `DAY n` + date |
| Ranking row | medal (gold/silver/bronze → neutral), name, landing time, avg |
| Total card | dark `ink` surface, big number, trophy icon |
| Buttons | primary (gradient), ghost (brand outline), dark, google (white+border) |
| Live indicator | `ok` green dot + "LIVE · updating now" |

## 6. Iconography

Line icons, `1.9` stroke, rounded caps (inline SVG set in the reference file). Filled variant for the active heart only.

## 7. Globalization (every country)

- **Languages:** Urdu · Hindi · Arabic · English.
- **RTL:** Urdu + Arabic mirror the layout (leading/trailing, not left/right). Use Flutter `Directionality`; never hard-code left/right padding.
- **Numerals & time:** locale-aware; times shown 12-hour (`12:40 PM`) — formatting per locale.
- **Fonts:** bundle an Arabic/Urdu-capable face (e.g. Noto Naskh/Noto Sans Arabic) alongside Inter for ur/ar.
- **Text expansion:** German/Arabic strings run longer — layouts use wrap/flex, no fixed-width labels.

## 8. Dark mode

Planned (not yet designed). Because colors are tokens, dark mode = a second token set. Track in `open-questions.md`.

---

*theme.md · Version 1.0 · 2026-10-03 · reference: `ui-high-fidelity.html`*
