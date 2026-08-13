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
  user_id uuid references auth.users(id) on delete cascade,
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
create index idx_attempts_user on attempts(user_id);

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

-- This app requires the user to be signed in (Supabase Auth, email + password).
-- Questions are readable by any authenticated user; attempts/answers are
-- scoped to the signed-in user via auth.uid().
create policy "authenticated read questions" on questions
  for select using (auth.role() = 'authenticated');

create policy "users read own attempts" on attempts
  for select using (auth.uid() = user_id);
create policy "users insert own attempts" on attempts
  for insert with check (auth.uid() = user_id);
create policy "users update own attempts" on attempts
  for update using (auth.uid() = user_id);

create policy "users read own attempt_answers" on attempt_answers
  for select using (
    exists (select 1 from attempts a where a.id = attempt_answers.attempt_id and a.user_id = auth.uid())
  );
create policy "users insert own attempt_answers" on attempt_answers
  for insert with check (
    exists (select 1 from attempts a where a.id = attempt_answers.attempt_id and a.user_id = auth.uid())
  );

-- Simple profile table (optional, not yet used by the UI beyond email display)
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  created_at timestamptz not null default now()
);
alter table profiles enable row level security;
create policy "users read own profile" on profiles for select using (auth.uid() = id);
create policy "users insert own profile" on profiles for insert with check (auth.uid() = id);
create policy "users update own profile" on profiles for update using (auth.uid() = id);
