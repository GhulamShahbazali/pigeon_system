# PigeonFly — Project Context

> **Purpose of this file:** the product concept, who it is for, the actors, and the scope of each module.
> For *decisions* (what is locked), see [`locked-decisions.md`](locked-decisions.md). For *unresolved items*, see [`open-questions.md`](open-questions.md).
> **Last updated:** 2026-10-03 · **Version:** 1.0

---

## 1. What is PigeonFly?

PigeonFly is a **mobile-first social platform for the pigeon-flying community** (*kabootar bazi*). Pigeon-flying enthusiasts and clubs already run informal competitions — releasing pigeons, recording when each bird lands, and comparing performance. Today this lives on paper, in phone calls, and in scattered WhatsApp groups.

PigeonFly brings it into one place:

- **Organizers** run **tournaments** — single- or multi-day competitions with rules, a set number of pigeons, a daily release time, and participants.
- **Everyone** can **discover and follow** public tournaments and see results update **live** — landing times, per-pigeon averages, and the overall average — day by day.
- **Enthusiasts** share **posts** (Facebook-style) and keep **personal daily records** of their own loft's flights, which they can keep private or broadcast live to their followers.
- A **web admin panel** lets the platform owner moderate and manage everything.

**One-line positioning:** *The home ground for pigeon-flying — run your tournament, follow the flights live, and share your loft.*

---

## 2. Who is it for? (Actors)

| Actor | Where | What they do |
|-------|-------|--------------|
| **User** | Mobile app | The base role. Discovers and views public tournaments and posts; follows, likes, and reports; keeps personal records; creates their own tournaments and posts; edits their profile and settings. |
| **Organizer** | Mobile app | *Not a separate account* — any **User** becomes an Organizer **for a tournament they create**. They alone can edit/update/delete that tournament and manage its participants. |
| **Follower** | Mobile app | A User who follows another User, a tournament, or a live personal record — and receives **real-time notifications** on updates. |
| **SuperAdmin** | Web admin panel | Full platform authority — view and moderate all content, handle reports, block users, and CRUD any tournament/post/record. |

> **Note:** "Organizer" is an **ownership relationship**, not a distinct account type. Permissions on a tournament are decided by *who created it*, not by a global role. (The only global elevated role is **SuperAdmin**.)

---

## 3. The modules

PigeonFly has **five** product modules. Each is specced in detail — and decided — in [`locked-decisions.md`](locked-decisions.md). This section is the *concept* of each.

### 3.1 Tournaments (the flagship module)

An Organizer creates a tournament and configures it **at creation time**:

- **Basics:** title, rules, description.
- **Duration:** how many **days** the tournament runs (1, 2, 3, 4, 5, … N).
- **Schedule:** pigeons are released **every day**, or **every other day** (alternate days).
- **Pigeon quantity:** the total number of pigeons that will fly in the tournament.
- **Timing:** the **release/fly time** and the **ending time**.
- **Participants:** the Organizer adds each participant — **name + image** required, and **contact number / phone / address optional**.

Once created:

- The tournament is **public** — any user can open it.
- Users can **follow** it and **like** it; **follow count, like count, and view (seen) count update in real time**.
- **Followers get notifications** carrying the tournament's updates as the Organizer records flights.
- **Only the Organizer** (creator) can edit, update, delete, or change participants.

**Browsing flow:**

```
Tournaments list
  → tap a tournament CARD
      → list of PARTICIPANTS (with the overall total average on the card)
          → tap a participant
              → participant DETAIL
```

**Multi-day display:** inside a tournament, each **day is a tab** labelled with its **date** (Day 1 · <date>, Day 2 · <date>, …). Each day's tab lists the pigeons for that day:

| Pigeon name | Landing time | Average |
|-------------|--------------|---------|

…followed by that **day's total average**. The **overall total average** (across all days) is shown **both** on the tournament detail screen **and** on the outer tournament card.

### 3.2 Posts (Facebook-style social feed)

A user composes a **post** manually, optionally attaches an **image**, and **publishes** it publicly. Each post supports:

- **Like** count, **share**, and **view** count.
- **Follow** the author (shown if the viewer follows that account).
- **Report** (to admin) and **Hide** (remove from the viewer's own feed).

The mechanics mirror a familiar social feed (like Facebook): public posts, engagement counters, and per-user moderation controls (report/hide).

### 3.3 Personal Records (my loft's daily routine)

A user logs their **own** daily flying routine — **"Add new day record"** — capturing:

- **Total pigeons flown** and the **release/fly time**.
- Per-pigeon **landing detail**: pigeon name, land time, and that pigeon's average.
- The record's **total average** across its list.

Each record has a **privacy choice**:

- **Private** → stored only (in the database); not shown to anyone else.
- **Live** → broadcast in real time. The owner's followers see the loft's landing detail update live, get a **notification** on each update, and the record carries **like and view (seen) counts**.

### 3.4 Settings & Profile

The Settings area is the user's control centre:

- **Notification permission** — allow/deny push notifications.
- **Privacy** — privacy controls for the account.
- **Language** — switch between **Urdu, Hindi, Arabic, English** (Urdu + Arabic render **right-to-left**).
- **Direct contact** — reach the PigeonFly team (support / contact us).
- **Profile** — visit and **edit** the user's own profile.
- **My content** — from here (and the profile) the user can create and view **their own tournaments, posts, and records**.

### 3.5 Admin Panel (web)

A **Next.js** web panel for the **SuperAdmin**, with **complete access** across the platform:

- View and act on **reports**.
- View, hide, or remove **posts**.
- View and manage **tournaments** (create / edit / delete).
- **Block** users and fetch any user's full detail.
- In short: **every** read and write across all content and users.

---

## 4. Scope

### In scope (MVP)

- Tournaments (create, multi-day, participants, public viewing, follow/like/view in real time, notifications)
- Posts (create, publish, like/share/view, follow, report, hide)
- Personal records (private or live, follower notifications)
- Settings (notifications, privacy, 4-language support, contact, profile edit)
- Web admin panel (full moderation + CRUD)

### Out of scope / later (to confirm)

- Monetization (payments, premium, ads) — **not specced**.
- In-app voice/video or live streaming of flights beyond text/number updates — **not specced**.
- Automated pigeon tracking hardware (GPS rings, sensors) — **not specced**.

> Anything not listed as "in scope" is **not** assumed. Add it to [`open-questions.md`](open-questions.md) before building.

---

## 5. Guiding principles

1. **Public by default, owner-controlled.** Tournaments and posts are public to view, but only their creator edits them.
2. **Live, not refresh.** Counts and follower notifications are expected to feel real-time.
3. **Local-first language.** Urdu/Hindi/Arabic/English, with proper RTL — this is a regional community product.
4. **One source of truth.** Every behaviour is decided in `locked-decisions.md` before it is coded.

---

*project-context.md · Version 1.0 · 2026-10-03*
