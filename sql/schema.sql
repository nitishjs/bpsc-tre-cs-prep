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

-- Profile table: name shown on the greeting and leaderboard, filled in at signup.
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  created_at timestamptz not null default now()
);
alter table profiles enable row level security;
create policy "users read own profile" on profiles for select using (auth.uid() = id);
create policy "users insert own profile" on profiles for insert with check (auth.uid() = id);
create policy "users update own profile" on profiles for update using (auth.uid() = id);

-- Auto-create a profile row the moment someone signs up (even before email
-- confirmation), capturing full_name from signUp's options.data.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Public leaderboard: best full-test merit % per participant, name + score only
-- (no email, no user_id exposed). Intentionally bypasses per-user RLS on
-- attempts, since a leaderboard is meant to be visible to every signed-in user.
create or replace view public.leaderboard as
select
  coalesce(nullif(p.full_name, ''), 'Participant') as display_name,
  a.set_number,
  a.merit_score,
  a.merit_total,
  round(a.merit_score::numeric / nullif(a.merit_total,0) * 100, 1) as merit_pct,
  a.submitted_at
from attempts a
join profiles p on p.id = a.user_id
where a.mode = 'full' and a.submitted_at is not null and a.merit_total > 0
order by merit_pct desc, a.submitted_at asc
limit 50;

grant select on public.leaderboard to authenticated;
