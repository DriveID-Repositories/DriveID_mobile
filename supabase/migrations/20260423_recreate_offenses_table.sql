begin;

-- Back up the current table so existing data is not destroyed.
drop table if exists public.offenses_backup;

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'offenses'
  ) then
    alter table public.offenses rename to offenses_backup;
  end if;
end $$;

create table if not exists public.offenses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  registration_number text not null,
  offense_type_id uuid references public.offense_types(id) on delete set null,
  offense_type text not null,
  location text not null,
  status text not null default 'Pending',
  fine text not null,
  created_at timestamp with time zone not null default now(),
  constraint offenses_status_check
    check (status in ('Pending', 'Paid', 'Resolved', 'Cleared'))
);

create index if not exists offenses_registration_number_idx
  on public.offenses (registration_number);

create index if not exists offenses_created_at_idx
  on public.offenses (created_at desc);

-- Restore rows from the backup when the old table had compatible fields.
do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'offenses_backup'
  ) then
    insert into public.offenses (
      id,
      name,
      registration_number,
      offense_type_id,
      offense_type,
      location,
      status,
      fine,
      created_at
    )
    select
      coalesce(id, gen_random_uuid()),
      coalesce(name, 'Unknown Driver'),
      coalesce(registration_number, license_number, register_number),
      offense_type_id,
      coalesce(offense_type, 'Unspecified Offense'),
      coalesce(location, 'Unknown Location'),
      coalesce(status, 'Pending'),
      coalesce(fine, amount, penalty_amount, penalty, 'TBD'),
      coalesce(created_at, now())
    from public.offenses_backup
    where coalesce(registration_number, license_number, register_number) is not null;
  end if;
exception
  when undefined_column then
    -- If the old table shape is too different, keep the backup and continue.
    null;
end $$;

alter table public.offenses enable row level security;

drop policy if exists "Allow all operations on offenses" on public.offenses;
create policy "Allow all operations on offenses"
  on public.offenses
  for all
  using (true)
  with check (true);

commit;
