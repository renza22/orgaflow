create or replace function public.is_org_member(org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.members m
    where m.organization_id = org_id
      and m.profile_id = auth.uid()
      and m.status = 'active'
  );
$$;

create or replace function public.create_organization_with_owner(
  p_name text,
  p_type_code text,
  p_description text default null,
  p_position_code text default null,
  p_division_code text default null,
  p_weekly_capacity_hours integer default 0,
  p_availability_status public.availability_status_enum default 'available'
)
returns table (
  organization_id uuid,
  member_id uuid,
  invite_code text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
  v_member_id uuid;
  v_invite_code text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  loop
    v_invite_code := public.generate_invite_code(p_name);
    exit when not exists (
      select 1 from public.organizations o where o.invite_code = v_invite_code
    );
  end loop;

  insert into public.organizations (
    name,
    type_code,
    invite_code,
    description,
    created_by
  ) values (
    p_name,
    p_type_code,
    v_invite_code,
    p_description,
    auth.uid()
  )
  returning id into v_org_id;

  insert into public.members (
    profile_id,
    organization_id,
    role,
    position_code,
    division_code,
    weekly_capacity_hours,
    availability_status,
    status
  ) values (
    auth.uid(),
    v_org_id,
    'owner',
    p_position_code,
    p_division_code,
    greatest(coalesce(p_weekly_capacity_hours, 0), 0),
    coalesce(p_availability_status, 'available'),
    'active'
  )
  returning id into v_member_id;

  return query
  select v_org_id, v_member_id, v_invite_code;
end;
$$;

create or replace function public.join_organization_by_invite_code(
  p_invite_code text,
  p_position_code text default null,
  p_division_code text default null,
  p_weekly_capacity_hours integer default 0,
  p_availability_status public.availability_status_enum default 'available'
)
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
  v_org_id uuid;
  v_member_id uuid;
  v_role public.member_role_enum;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select o.id
    into v_org_id
  from public.organizations o
  where upper(o.invite_code) = upper(trim(p_invite_code))
    and o.is_active = true;

  if v_org_id is null then
    raise exception 'Invite code not found or organization inactive';
  end if;

  insert into public.members (
    profile_id,
    organization_id,
    role,
    position_code,
    division_code,
    weekly_capacity_hours,
    availability_status,
    status
  ) values (
    auth.uid(),
    v_org_id,
    'member',
    p_position_code,
    p_division_code,
    greatest(coalesce(p_weekly_capacity_hours, 0), 0),
    coalesce(p_availability_status, 'available'),
    'active'
  )
  on conflict (profile_id, organization_id)
  do update set
    position_code = excluded.position_code,
    division_code = excluded.division_code,
    weekly_capacity_hours = excluded.weekly_capacity_hours,
    availability_status = excluded.availability_status,
    status = 'active',
    updated_at = now()
  returning id, members.role into v_member_id, v_role;

  return query
  select v_org_id, v_member_id, v_role;
end;
$$;

revoke all on function public.create_organization_with_owner(text, text, text, text, text, integer, public.availability_status_enum) from public;
revoke all on function public.join_organization_by_invite_code(text, text, text, integer, public.availability_status_enum) from public;
grant execute on function public.create_organization_with_owner(text, text, text, text, text, integer, public.availability_status_enum) to authenticated;
grant execute on function public.join_organization_by_invite_code(text, text, text, integer, public.availability_status_enum) to authenticated;
