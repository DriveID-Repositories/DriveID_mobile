begin;

-- Update offenses table to use license_number
-- Add license_number column if it doesn't exist
alter table if exists public.offenses add column if not exists license_number text;

-- Populate license_number from registration_number if empty
update public.offenses set license_number = registration_number where license_number is null;

-- Drop old index on registration_number
drop index if exists public.offenses_registration_number_idx;

-- Create index on license_number
create index if not exists offenses_license_number_idx on public.offenses (license_number);

-- Recreate verifications table with license_number instead of registration_number
drop table if exists public.verifications_backup;

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'verifications'
  ) then
    alter table public.verifications rename to verifications_backup;
  end if;
end $$;

create table if not exists public.verifications (
  id uuid default gen_random_uuid() primary key,
  license_number text not null,
  verified_at timestamp with time zone default now()
);

create index if not exists verifications_license_number_idx on public.verifications (license_number);

-- Restore data from backup if it exists
do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'verifications_backup'
  ) then
    insert into public.verifications (id, license_number, verified_at)
    select
      coalesce(id, gen_random_uuid()),
      coalesce(registration_number, license_number, register_number),
      verified_at
    from public.verifications_backup
    where coalesce(registration_number, license_number, register_number) is not null;
  end if;
exception
  when undefined_column then
    null;
end $$;

alter table public.verifications enable row level security;

drop policy if exists "Allow all operations on verifications" on public.verifications;
create policy "Allow all operations on verifications"
  on public.verifications
  for all
  using (true)
  with check (true);

commit;
