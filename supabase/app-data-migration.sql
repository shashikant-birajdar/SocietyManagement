-- One-time upgrade for projects where schema.sql was already applied.
-- The application stores each society's working records in this JSON document.
-- Existing RLS policies on public.societies restrict reads to the society and
-- updates to its admin, so this column inherits those access rules.
alter table public.societies
  add column if not exists app_data jsonb not null default '{}'::jsonb;

notify pgrst, 'reload schema';

