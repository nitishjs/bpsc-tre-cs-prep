-- BPSC TRE 4.0 Computer Science Practice Portal — Database Schema
-- Run this first in a fresh Supabase (or any Postgres) database,
-- then run sql/seed_data.sql to load all 750 questions.

create table questions (
  id bigserial primary key,
  set_number int not null,           -- 1 to 5 (5 independent practice sets)
  part int not null,                 -- 1 = Language, 2 = GS, 3 = CS
  section text not null,             -- English / Hindi / GS / CS
  topic text not null,
  q_no int not null,                 -- position within the part (1..N)
  question text not null,
  option_a text not null,
  option_b text not null,
  option_c text not null,
  option_d text not null,
  correct_option char(1) not null check (correct_option in ('A','B','C','D','E')),
  explanation text not null,
  difficulty text not null default 'M'   -- E = Easy, M = Medium, H = Hard
);

create index idx_questions_set_part on questions(set_number, part);

create table attempts (
  id uuid primary key default gen_random_uuid(),
  mode text not null,                -- 'section' or 'full'
  set_number int not null,
  part int,                          -- null for full test
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  duration_seconds int,
  merit_score numeric,
  merit_total numeric,
  language_score numeric,
  language_total numeric
);

create table attempt_answers (
  id bigserial primary key,
  attempt_id uuid not null references attempts(id) on delete cascade,
  question_id bigint not null references questions(id),
  selected_option char(1),           -- null = unanswered
  is_correct boolean
);

alter table questions enable row level security;
alter table attempts enable row level security;
alter table attempt_answers enable row level security;

-- Public read/write policies: this is a single-user personal practice app
-- using the Supabase anon key client-side. If you deploy this for multiple
-- users or add auth, tighten these policies accordingly.
create policy "public read questions" on questions for select using (true);
create policy "public read attempts" on attempts for select using (true);
create policy "public insert attempts" on attempts for insert with check (true);
create policy "public update attempts" on attempts for update using (true);
create policy "public read attempt_answers" on attempt_answers for select using (true);
create policy "public insert attempt_answers" on attempt_answers for insert with check (true);
