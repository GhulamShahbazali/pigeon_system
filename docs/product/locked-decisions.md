# PigeonFly — Locked Decisions (SSOT)

> **This file is law.** Every product/feature behaviour is decided here. If code or a technical doc disagrees with this file, **this file wins** for product intent.
> Legend: ✅ **Locked** · 🟡 **Draft** (agreed in concept, wording may refine) · ❓ **Open** (tracked in [`open-questions.md`](open-questions.md))
> **Last updated:** 2026-10-03 · **Version:** 1.0

---

## 0. Global

| # | Decision | Value | Status |
|---|----------|-------|--------|
| G1 | Product name | **PigeonFly** (working title) | 🟡 |
| G2 | Platforms | Flutter mobile (Android + iOS) + Next.js admin web | ✅ |
| G3 | Repo layout | Monorepo — `mobile/` · `backend/` · `admin/` · `docs/` | ✅ |
| G4 | Modules | Tournaments · Posts · Personal Records · Settings · Admin panel | ✅ |
| G5 | Supported languages | **Urdu · Hindi · Arabic · English** | ✅ |
| G6 | Text direction | Urdu + Arabic = **RTL**; Hindi + English = LTR | ✅ |
| G7 | Default language | ❓ device locale vs English | ❓ |
| G8 | Global elevated role | **SuperAdmin** only (web panel). No other global roles. | ✅ |
| G9 | Deletion policy | **Soft-delete / hide** content; never hard-delete rows referenced by other records | 🟡 |
| G10 | Monetization | **Not in MVP** — no payments/premium/ads | 🟡 |
| G11 | Landing screen | **Home** — a dashboard shown first after sign-in | ✅ |
| G12 | Bottom navigation | **Home · Tournaments · ＋ (create) · Records · Profile** | ✅ |
| G13 | Home contents | **Live now** strip · **featured tournament(s)** · **posts feed** (the posts feed lives inside Home — no separate Posts tab) | ✅ |
| G14 | Creating content | the center **＋** opens create (tournament / post / record) | ✅ |

---

## 1. Accounts & Authentication

| # | Decision | Value | Status |
|---|----------|-------|--------|
| A1 | One account type for the app | **User** (Organizer = a User who owns a tournament) | ✅ |
| A2 | Sign-up / login method | **Google sign-in (passwordless)** — no password in-app | ✅ |
| A2b | Apple sign-in | Offered on **iOS** (optional — confirm) | ❓ |
| A3 | Profile fields | name + image pre-filled from Google; username, language — **exact set pending** | 🟡 |
| A4 | Admin login | Separate credentials in the **web panel** (not the app) | 🟡 |
| A5 | Account blocking | SuperAdmin can **block** a user (blocks login + hides their content) | ✅ |

> **Auth method locked:** Google sign-in. Apple-on-iOS (A2b) still open. First-time users complete a short profile setup; returning users skip it.

---

## 2. Tournaments Module

### 2.1 Ownership & permissions

| # | Decision | Value | Status |
|---|----------|-------|--------|
| T1 | Who can create a tournament | **Any user** | ✅ |
| T2 | Who can edit / update / delete a tournament | **Only its creator (owner)** | ✅ |
| T3 | Who can add / edit / remove participants | **Only the owner** | ✅ |
| T4 | Visibility | **Public** — any user can view any tournament | ✅ |
| T5 | SuperAdmin override | SuperAdmin can edit/delete any tournament from the web panel | ✅ |

### 2.2 Creation config (set at creation time)

| # | Field | Value | Status |
|---|-------|-------|--------|
| T6 | Title | required text | ✅ |
| T7 | Rules | text | ✅ |
| T8 | Description | text (optional) | 🟡 |
| T9 | Number of days | integer **1..N** (single- or multi-day) | ✅ |
| T10 | Schedule type | **Every day** OR **Alternate days** (every other day) | ✅ |
| T11 | Pigeon quantity | integer set at creation — the pigeon count EACH participant flies (same for all). It is the **maximum recordable** per participant: you may record **fewer** landing entries (the missing ones = **not returned**), but **never more** than this count | ✅ |
| T12 | Release / fly time | time-of-day | ✅ |
| T13 | Ending time | time-of-day | ✅ |
| T14 | Start date | date (Day 1); subsequent day dates derive from T9 + T10 | 🟡 |
| T14b | **Organizer contact number** | the creator provides a **contact number** at creation; shown on the tournament | ✅ |
| T14c | Contact actions (detail page) | tapping the **☎ contact icon** opens a dialog: **WhatsApp · WhatsApp Business · Call (dial pad) · Copy number** — the chosen app opens pre-filled with that number | ✅ |
| T14d | **Share a participant's record** | the **share icon** opens a dialog to export that participant's day-by-day record as **Excel (.xlsx) · PDF · Text · Image** — each a clean, professional format, then handed to the system share sheet | ✅ |
| T14e | **Share the whole tournament (link)** | share dialog gives a **shareable link** (copy / share) + export standings (Excel/PDF) | ✅ |
| T14f | **Smart deep link** | opening a tournament link: **app installed → opens that tournament directly**; **not installed → store (App Store / Google Play) → after install the tournament opens automatically** (deferred deep link) | ✅ |
| T15 | Can config be edited after creation? | ❓ fully editable / locked once flights recorded | ❓ |

### 2.3 Participants

| # | Decision | Value | Status |
|---|----------|-------|--------|
| T16 | Participant name | **required** | ✅ |
| T17 | Participant image | **required** | 🟡 |
| T18 | Contact number ("chat no") | **optional** | ✅ |
| T19 | Phone number | **optional** | ✅ |
| T20 | Address | **optional** | ✅ |
| T21 | Is a participant a PigeonFly user account, or just a record? | ❓ | ❓ |

### 2.4 Flights, days & averages

| # | Decision | Value | Status |
|---|----------|-------|--------|
| T22 | Per day, each participant/pigeon has | **pigeon name · landing time · average** | ✅ |
| T23 | Day display | each **day = a tab**, labelled with its **date** | ✅ |
| T24 | Per-day total | **day total average** shown under that day's list | ✅ |
| T25 | Overall total | **overall total average** across all days | ✅ |
| T26 | Where overall average appears | on the tournament **detail** screen and in the **standings / participant rows** — **not** as a badge on the list card (removed per owner feedback 2026-10-03) | ✅ |
| T27 | Average / score | per pigeon: **flight duration = landing time − fly time** (hours). Participant score = **sum/average of their pigeons' durations**. **Higher = better** (longest total flight time wins — endurance). Ranking is **descending** | ✅ |
| T27b | "Not returned" in the average | a pigeon that doesn't return is **never recorded** (no landing time entered) → **not counted at all**. The average is over the **returned (recorded) pigeons only** (denominator = returned count). | ✅ |
| T28 | Pigeons per participant | **multiple** — each flies up to T11 pigeons; the owner records a name + landing time for each **returned** pigeon (count ≤ T11); each has its own row per day | ✅ |

### 2.5 Social & realtime

| # | Decision | Value | Status |
|---|----------|-------|--------|
| T29 | Follow a tournament | any user can follow | ✅ |
| T30 | Like a tournament | any user can like; **like count is real-time** | ✅ |
| T31 | View / seen count | tracked and shown; **real-time** | ✅ |
| T32 | Who gets tournament notifications | **followers** of the organizer (and anyone following the tournament) | ✅ |
| T33 | Notification triggers | **(a) tournament created · (b) each new participant added · (c) flight / pigeon detail added (day results)** | ✅ |
| T33b | Flight-add throttling | whether every single landing pushes a notification or they're batched per update is a **delivery detail** (tune later) | 🟡 |

### 2.6 Browsing flow (locked)

```
Tournaments list → tap CARD → PARTICIPANTS list → tap participant → participant DETAIL
```
Card shows: title, schedule summary, **overall total average**, like/view counts.

---

## 3. Posts Module

| # | Decision | Value | Status |
|---|----------|-------|--------|
| P1 | Who can create a post | any user | ✅ |
| P2 | Composition | **manual** text + optional **image** | ✅ |
| P3 | Publish | user publishes **publicly** | ✅ |
| P4 | Image count per post | ❓ one or many | ❓ |
| P5 | Engagement | **like count · share · view count** | ✅ |
| P6 | Follow author | shown if the author's account is followed by the viewer | ✅ |
| P7 | Report | any user can **report** a post (goes to admin) | ✅ |
| P8 | Hide | a user can **hide** a post from their own feed | ✅ |
| P9 | Edit / delete own post | ❓ (assumed owner-only — confirm) | ❓ |
| P10 | Feed model | public feed, Facebook-style engagement | 🟡 |
| P11 | Feed ordering | ❓ chronological / ranked | ❓ |

---

## 4. Personal Records Module

| # | Decision | Value | Status |
|---|----------|-------|--------|
| R1 | Purpose | log the user's **own** daily pigeon-flying routine | ✅ |
| R2 | Entry action | **"Add new day record"** | ✅ |
| R3 | Record header fields | **total pigeons flown · release/fly time** | ✅ |
| R4 | Per-pigeon detail | **pigeon name · land time · average** | ✅ |
| R5 | Record total | **total average** of the record's list | ✅ |
| R6 | Privacy choice | **Private (stored only)** OR **Live (broadcast)** | ✅ |
| R7 | Default privacy | ❓ private vs live by default | ❓ |
| R8 | Live behaviour | live record updates in **real time** on followers' feeds | ✅ |
| R9 | Live engagement | live records carry **like + view (seen) counts** | ✅ |
| R10 | Live notifications | followers get a **notification** on each live update | ✅ |
| R11 | Can a private record be made live later (and vice-versa)? | ❓ | ❓ |
| R12 | Where live records show to followers | a **"Live now"** list in the Records tab + a notification; tap → live detail | ✅ |
| R13 | Owner can edit / delete pigeons | each pigeon row (name · landing time) is **editable and deletable** by the owner; average recomputes | ✅ |
| R14 | **Daily live auto-end** | at **midnight** every live record's broadcast **auto-ends** (`live → completed`) | ✅ |
| R15 | Auto-end timezone | **each user's own local (device) time** — PKT user at 00:00 PKT, IST user at 00:00 IST | ✅ |
| R16 | Record retained on auto-end | the record is **never deleted** — it stays in the owner's **My Records** history as a completed day (keeps its privacy) | ✅ |
| R17 | Pigeons not landed by cutoff | marked **"Not returned"** at auto-end — handling in the average depends on the formula | 🟡 (ties to T27/Q2) |
| R18 | Followers on auto-end | live view switches to an **"Ended"** state + a final "flying ended · avg X" notification | ✅ |
| R19 | Storage location | records are stored **server-side (PostgreSQL)**, not device-only, so history/other devices keep them | ✅ |

---

## 5. Settings & Profile Module

| # | Decision | Value | Status |
|---|----------|-------|--------|
| S1 | Notification permission | toggle to allow/deny push | ✅ |
| S2 | Privacy settings | privacy controls present | 🟡 (contents ❓) |
| S3 | Language switcher | **Urdu · Hindi · Arabic · English**, with RTL for ur/ar | ✅ |
| S4 | Direct contact | contact / support entry point | ✅ |
| S5 | Profile | visit own profile + **edit** | ✅ |
| S6 | Create/view own content from here | tournaments, posts, records manageable from settings/profile | ✅ |
| S7 | Edit-profile location | ❓ settings-only vs also from profile screen | ❓ |

---

## 6. Admin Panel (Web)

| # | Decision | Value | Status |
|---|----------|-------|--------|
| AD1 | Platform | **Next.js** web panel | ✅ |
| AD2 | Data access | via the **backend API only** — never direct DB | ✅ |
| AD3 | Access level | **Full** — read + write across everything | ✅ |
| AD4 | Reports | view and act on user reports | ✅ |
| AD5 | Posts | view / hide / remove any post | ✅ |
| AD6 | Tournaments | view / create / edit / delete any tournament | ✅ |
| AD7 | Users | **block** users, fetch full user detail | ✅ |
| AD8 | Records | ❓ can admin view private personal records? | ❓ |
| AD9 | Admin roles | single SuperAdmin vs multiple admin tiers | ❓ |

---

## 6B. Messages & Chat Module

| # | Decision | Value | Status |
|---|----------|-------|--------|
| M1 | Chat type | **1-to-1 direct messages** | ✅ |
| M2 | Message types | **text · voice note · image · video** | ✅ |
| M3 | First-message rule | messaging a **new** person sends **one message only**, as a **request** (TikTok-style) | ✅ |
| M4 | Continue talking | the sender can send more **only after the recipient Accepts** the request | ✅ |
| M5 | Request actions | recipient can **Accept · Delete · Block** | ✅ |
| M6 | Block | blocking **stops delivery instantly**; unblock from the chat | ✅ |
| M7 | Ticks | **✓ sent · ✓✓ delivered · ✓✓ (blue) read** (WhatsApp-style) | ✅ |
| M8 | Blocked delivery | a blocked sender's messages stay on a **single ✓** (never delivered) | ✅ |
| M9 | Entry point | **chat icon in the Home header** → inbox (chats + requests) | ✅ |
| M10 | Report | report a user from the chat options | ✅ |
| M11 | Voice / video limits | max length & file size — **pending** | ❓ |
| M12 | Mutual-follow gate? | is messaging open to anyone, or only follows/mutuals? — **pending** | ❓ |

## 7. Cross-cutting

| # | Decision | Value | Status |
|---|----------|-------|--------|
| X1 | Realtime transport | counts + notifications are **live** (Socket.io assumed) | 🟡 |
| X2 | Notifications channel | push (FCM assumed) + in-app | 🟡 |
| X3 | Media storage | images stored off-device (object storage) | 🟡 |
| X4 | Dates & times | 12-hour time display; locale-aware dates | 🟡 |
| X5 | Moderation outcomes | report → admin review → hide/remove/block | 🟡 |

---

## Change log

- **v1.0 (2026-10-03):** Initial product decisions captured from the lead's spec — Tournaments, Posts, Personal Records, Settings, Admin panel. Items marked ❓ moved to `open-questions.md`.

---

*locked-decisions.md · Version 1.0 · 2026-10-03*
