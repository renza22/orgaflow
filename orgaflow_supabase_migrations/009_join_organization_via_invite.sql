begin;

create or replace function public.join_organization_by_invite_code(invite_code text)
returns table (
  organization_id uuid,
  member_id uuid,
  role public.member_role_enum
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid := auth.uid();
  v_org_id uuid;
  v_member_id uuid;
  v_normalized_invite_code text;
begin
  if v_profile_id is null then
    raise exception 'Unauthorized'
      using errcode = '42501';
  end if;

  v_normalized_invite_code :=
    regexp_replace(upper(trim(invite_code)), '\s+', '', 'g');

  select o.id
    into v_org_id
  from public.organizations o
  where regexp_replace(upper(o.invite_code), '\s+', '', 'g') = v_normalized_invite_code
    and o.is_active = true
  limit 1;

  if v_org_id is null then
    raise exception 'Kode organisasi tidak ditemukan'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from public.profiles p
    where p.id = v_profile_id
  ) then
    insert into public.profiles (id, email)
    select u.id, u.email
    from auth.users u
    where u.id = v_profile_id
    on conflict (id) do nothing;
  end if;

  insert into public.members (
    profile_id,
    organization_id,
    role,
    status,
    availability_status,
    weekly_capacity_hours,
    capacity_used_hours,
    joined_at
  )
  values (
    v_profile_id,
    v_org_id,
    'member',
    'active',
    'available',
    0,
    0,
    now()
  )
  on conflict (profile_id, organization_id)
  do update
    set status = 'active',
        updated_at = now()
  returning public.members.id
    into v_member_id;

  return query
  select
    v_org_id as organization_id,
    v_member_id as member_id,
    m.role
  from public.members m
  where m.id = v_member_id;
end;
$$;

revoke all on function public.join_organization_by_invite_code(text) from public;
grant execute on function public.join_organization_by_invite_code(text) to authenticated;

commit;