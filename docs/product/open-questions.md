# PigeonFly — Open Questions & TODO Backlog

> Everything still **undecided**. Nothing here may be guessed in code — resolve it, move the answer into [`locked-decisions.md`](locked-decisions.md), and delete it from this list.
> **Last updated:** 2026-10-03 · **Version:** 1.0

---

## 🔴 Blocking (resolve before building the related module)

| # | Ref | Question | Why it blocks |
|---|-----|----------|---------------|
| ~~Q1~~ | A2 | ~~How do users sign up / log in?~~ → **RESOLVED 2026-10-03: Google sign-in (passwordless).** Apple-on-iOS still optional (see Q1b). | — |
| Q1b | A2b | **Offer Apple sign-in on iOS?** (App Store review often requires it if any third-party social login is present.) | Affects iOS onboarding + Firebase config. |
| ~~Q2~~ | T27 | ~~How is "average" computed?~~ → **RESOLVED 2026-10-03:** per-pigeon **flight duration** (landing − fly time, hours); participant score = sum/average of durations; **higher = winner** (endurance), descending. Only sub-detail Q2b (locked T27b) remains: does the average divide by returned or total pigeons? |
| ~~Q2b~~ | T27b | ~~"Not returned" averaging?~~ → **RESOLVED 2026-10-03:** a not-returned pigeon is **never recorded**, so it's **not counted**. Average = over returned (recorded) pigeons only. |
| ~~Q3~~ | T28 | ~~Pigeon vs participant?~~ → **RESOLVED 2026-10-03: multiple pigeons per participant** — each flies exactly the tournament's pigeon count; each pigeon has its own name + landing time per day. |
| ~~Q4~~ | T11 | ~~What does "pigeon quantity" mean?~~ → **RESOLVED 2026-10-03: the number EACH participant flies** (same for all, fixed at creation). |

---

## 🟠 Important (resolve before that module ships)

| # | Ref | Question |
|---|-----|----------|
| Q5 | T10/T14 | For **alternate-day** schedules, do day tabs show only flying days, or all calendar days? How are the dates generated from start date + schedule? |
| ~~Q6~~ | T15 | ~~**Can a tournament's config be edited after creation**, or is it locked once flights are recorded?~~ → **RESOLVED 2026-10-31:** cosmetic/contact fields (title, description, rules, cover, organizer contact) editable anytime; schedule-defining fields (num_days, schedule_type, start_date, pigeon_count, fly/end time) locked at creation (T15). |
| ~~Q7~~ | T32/T33 | ~~What triggers a follower notification?~~ → **RESOLVED 2026-10-03:** tournament created · new participant added · flight/day-results added (locked T33). Only per-landing throttling left as a delivery detail. |
| Q8 | T17 | Is a participant **image required or optional**? (Spec listed it among optional contact fields but also as a core field.) |
| Q9 | T21 | Is a **participant a real PigeonFly user account**, or just a record the organizer types in? |
| Q10 | R7/R11 | Personal records: **default privacy**? Can a private record be switched to live later (and back)? |
| Q11 | P4/P9/P11 | Posts: **how many images** per post? Can the author **edit/delete**? Feed **ordering** (chronological vs ranked)? |
| Q12 | AD8 | Can the **admin view private personal records**? (Privacy vs moderation trade-off.) |

---

## 🟡 Secondary (can default, confirm later)

| # | Ref | Question |
|---|-----|----------|
| Q13 | G7 | **Default app language** — device locale or English? |
| Q14 | A3 | Exact **profile fields** (bio, location, contact visibility). |
| Q15 | S2/S7 | Contents of **privacy settings**; is edit-profile settings-only? |
| Q16 | AD9 | **One SuperAdmin** or multiple admin tiers/permissions? |
| Q17 | G10 | Any **monetization** direction to design around now (even if built later)? |

---

## 🏗️ Structural / technical TODO (not product, but pending)

| # | Item |
|---|------|
| TS1 | **Confirm the tech stack** and write `docs/technical/tech-stack-decisions.md`. Assumed: Flutter · NestJS · Next.js · PostgreSQL/Prisma · Socket.io · FCM — the lead said the app/backend/admin already exist, so confirm what was actually built. |
| TS2 | **Monorepo split** — today `pigeon_system/` is a single Flutter scaffold at the root. Move it to `mobile/` and add `backend/` + `admin/` (Talksy layout), or keep the app at root? |
| TS3 | Write **`docs/technical/schema/`** (DB) once Q2–Q4 are resolved. |
| TS4 | Write **`docs/technical/api/`** (REST + realtime contract). |
| TS5 | Produce **wireframes / screen inventory** in `docs/wireframes/`. |
| TS6 | Decide **realtime transport** (Socket.io assumed) and **push** (FCM assumed) — confirm in the stack doc. |
| TS7 | Pick a **deep-link / deferred-deep-link** provider for tournament links (locked T14f). Firebase Dynamic Links is being shut down (Aug 2025) — evaluate **Branch, Adjust, AppsFlyer OneLink**, or a custom universal-links + install-referrer solution. Needs a small **web landing page** at `pigeonfly.app/t/<id>`. |

---

## How to use this file

1. Pick an item, discuss with the lead, decide.
2. Write the decision into `locked-decisions.md` (flip ❓ → ✅/🟡).
3. Delete the item here (or strike it through with the resolution date).
4. If a new unknown appears mid-build, **add it here first** — don't guess in code.

---

*open-questions.md · Version 1.0 · 2026-10-03*
