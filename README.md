# BPSC TRE 4.0 — Computer Science Practice Portal

A self-contained practice exam app for the **Bihar BPSC TRE 4.0 Computer Science Teacher** recruitment exam (General Category). Built as a single static page backed by Supabase, deployed on Vercel — no build step, no framework, no npm install required to run it.

**Live app:** https://bpsc-tre-cs-prep-big-bang1.vercel.app

## What's included

- **Email + password sign-in** (Supabase Auth) — every user's attempt history is private to their own account.
- **750 questions** across **5 independent full-length sets** (Set 1–5), each set structured exactly like the real exam:
  - Part I — Language: 30 Qs (10 English + 20 Hindi), qualifying only
  - Part II — General Studies: 40 Qs (Math & Reasoning, Science, Current Affairs & Polity, History, Indian & Bihar Geography)
  - Part III — Computer Science: 80 Qs (Computer Fundamentals, System Software, Data Structures, C/C++ & OOP, DBMS & SQL, Computer Networks, Computer Architecture, Number Systems & Boolean Algebra, Cyber Security)
- Every question has all 4 options, the correct answer, a topic tag, and a written explanation.
- **Section-wise practice** (pick any set + Language/GS/CS) with a proportional timer.
- **Full-length mock test**: 150 questions, exact 150-minute countdown, auto-submits at time-up.
- **Evaluation**: Merit score (Part II+III /120, since Part I is qualifying-only), verdict vs. a projected cut-off range, topic-wise accuracy bars, and a weak-areas callout.
- **Full solution review** after every attempt: all 4 options shown, correct one highlighted, your wrong pick flagged, explanation underneath.
- **Attempt history**, saved to Supabase and shown on the home screen.
- Mobile-responsive: sticky timer, collapsing question palette, full-width buttons on small screens.

## Repo structure

```
index.html          The entire app — HTML, CSS, and JS in one file
sql/schema.sql       Database schema (3 tables: questions, attempts, attempt_answers)
sql/seed_data.sql    All 750 questions as INSERT statements
```

## How it works

`index.html` is a plain HTML page. It loads the Supabase JS client from a CDN
(`https://esm.sh/@supabase/supabase-js@2`) and talks directly to a Supabase
Postgres database using the public **anon key** (safe to expose — access is
governed by Row Level Security policies in `schema.sql`, not by hiding the key).

There is no backend server and no build step. You can open `index.html`
directly in a browser, or serve it from any static host.

## Running your own copy

1. **Create a Supabase project** at [supabase.com](https://supabase.com) (free tier is enough).
2. In the Supabase SQL Editor, run `sql/schema.sql`, then `sql/seed_data.sql`.
3. In `index.html`, replace the two constants near the top of the `<script>` block with your own project's values (Project Settings → API):
   ```js
   const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
   const SUPABASE_KEY = 'YOUR-ANON-KEY';
   ```
4. Deploy `index.html` anywhere that serves static files — Vercel, Netlify, GitHub Pages, or just open it locally. No build command needed.

### Deploying to Vercel (what this project uses)

```bash
npm i -g vercel
vercel --prod
```
Vercel will detect the static `index.html` automatically — no framework preset needed.

### Deploying to GitHub Pages

Enable Pages on this repo (Settings → Pages → Deploy from branch → `main` / root), and it will serve `index.html` directly.

## Extending it

- **More sets**: add rows to `questions` with a new `set_number` (6, 7, ...), then add that number to the `AVAILABLE_SETS` array near the top of the script in `index.html`.
- **Multiplayer / shared leaderboard**: the `attempts` table already logs every attempt with a score; add a query to rank them.
- **Auth**: currently all data is public (single-user personal tool). Add Supabase Auth and tighten the RLS policies in `schema.sql` if you want per-user history.

## Notes

- The Language section (Part I) is scored separately and is **qualifying only** per the real BPSC TRE pattern — it does not count toward the Merit score shown on the results screen.
- The 82–87% "cut-off zone" shown on the results screen is an informal projection for self-assessment, not an official BPSC figure.
- Question content was authored for this project in the style and topic distribution of past BPSC TRE Computer Science papers; it is original practice material, not reproduced exam questions.

## License

MIT — use, modify, and redistribute freely.
