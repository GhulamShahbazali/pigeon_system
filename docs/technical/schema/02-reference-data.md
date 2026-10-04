[← Back to schema index](index.md)

---

# Section 2: Reference Data

> Read-mostly lookup tables. Seeded, rarely changed. Served with an ETag (`reference_data:etag:{table}`) so clients cache.

## Table: `countries`
| Column | Type | Req | Notes |
|--------|------|-----|-------|
| `code` | string | Yes | PK — ISO 3166-1 alpha-2 (`PK`, `IN`, …) |
| `name` | string | Yes | English name |
| `dial_code` | string | No | `+92` |
| `flag_emoji` | string | No | |

## Table: `languages`
| Column | Type | Req | Notes |
|--------|------|-----|-------|
| `code` | string | Yes | PK — ISO 639-1 (`ur`, `hi`, `ar`, `en`) |
| `name` | string | Yes | English name |
| `native_name` | string | No | `اردو` |
| `is_rtl` | boolean | Yes | true for `ur`, `ar` |

> App language is limited to these four (G5). `is_rtl` drives layout mirroring.

---

*Section 2: Reference Data · v0.1 · 2026-10-03*
