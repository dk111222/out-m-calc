-- Logical contract for StepMath Hive boxes.
-- Do not run this against Postgres, Supabase, or any server.
-- The app store is Hive on device. Type ids live in replica/architecture.md.
-- UUID defaults below mean "the domain generates a string id before put".

-- learners
-- delete learner => delete attempts, wrong_items, speed_rounds, mastery,
-- assignments, session_snapshots, certificates for that learner
create table learners (
  id text primary key,
  display_name text not null default 'Learner',
  grade text not null check (grade in ('K','1','2','3','4','5')),
  created_at timestamptz not null,
  updated_at timestamptz not null
);

-- singleton key: device
create table device_settings (
  id text primary key check (id = 'device'),
  parent_pin_hash text,
  telemetry_enabled boolean not null default false,
  active_learner_id text references learners(id) on delete set null,
  extra_learners_unlocked boolean not null default false,
  print_unlocked boolean not null default false,
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create table attempts (
  id text primary key,
  learner_id text not null references learners(id) on delete cascade,
  trick_id text not null,
  prompt text not null,
  user_answer text not null,
  correct_answer text not null,
  correct boolean not null,
  failed_step integer,
  mode text not null check (mode in ('guided','final','speed')),
  created_at timestamptz not null
);
create index attempts_learner_created on attempts (learner_id, created_at);
create index attempts_learner_trick on attempts (learner_id, trick_id);

create table wrong_items (
  id text primary key,
  learner_id text not null references learners(id) on delete cascade,
  attempt_id text not null references attempts(id) on delete cascade,
  trick_id text not null,
  failed_step integer,
  reviewed_ok boolean not null default false,
  created_at timestamptz not null,
  updated_at timestamptz not null
);
create index wrong_items_queue on wrong_items (learner_id, reviewed_ok, created_at);

create table speed_rounds (
  id text primary key,
  learner_id text not null references learners(id) on delete cascade,
  operation text not null,
  digit_min integer not null,
  digit_max integer not null,
  limit_mode text not null check (limit_mode in ('time','count')),
  limit_value integer not null check (limit_value > 0),
  correct_count integer not null default 0,
  duration_ms integer not null default 0,
  created_at timestamptz not null
);
create index speed_rounds_learner on speed_rounds (learner_id, created_at);

create table mastery (
  learner_id text not null references learners(id) on delete cascade,
  trick_id text not null,
  last_20_correct_rate numeric not null default 0,
  mastered boolean not null default false,
  mastered_at timestamptz,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  primary key (learner_id, trick_id)
);

create table assignments (
  id text primary key,
  learner_id text not null references learners(id) on delete cascade,
  local_date text not null,
  kind text not null check (kind in ('learn','speed')),
  trick_id text,
  speed_config text,
  status text not null check (status in ('open','done','replaced')),
  created_at timestamptz not null,
  updated_at timestamptz not null
);
create unique index one_open_assignment
  on assignments (learner_id, local_date)
  where status = 'open';

create table session_snapshots (
  learner_id text primary key references learners(id) on delete cascade,
  module text not null check (module in ('learn','speed')),
  trick_id text,
  prompt_list text not null,
  index_in_round integer not null default 0,
  draft_input text not null default '',
  updated_at timestamptz not null
);

create table certificates (
  id text primary key,
  learner_id text not null references learners(id) on delete cascade,
  kind text not null check (kind in ('trick','speed')),
  trick_id text,
  speed_round_id text references speed_rounds(id) on delete set null,
  title text not null,
  issued_at timestamptz not null
);
create index certificates_learner on certificates (learner_id, issued_at);
