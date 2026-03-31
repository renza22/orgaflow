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
  v_normalized_code text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  v_normalized_code := regexp_replace(upper(trim(p_invite_code)), '\s+', '', 'g');

  select o.id
    into v_org_id
  from public.organizations o
  where regexp_replace(upper(o.invite_code), '\s+', '', 'g') = v_normalized_code
    and o.is_active = true
  limit 1;

  if v_org_id is null then
    raise exception 'Invite code not found or organization inactive';
  end if;

  insert into public.profiles (id, email)
  select u.id, u.email
  from auth.users u
  where u.id = auth.uid()
  on conflict (id) do nothing;

  select m.id, m.role
    into v_member_id, v_role
  from public.members m
  where m.profile_id = auth.uid()
    and m.organization_id = v_org_id
  limit 1;

  if v_member_id is not null then
    update public.members m
    set
      position_code = coalesce(p_position_code, m.position_code),
      division_code = coalesce(p_division_code, m.division_code),
      weekly_capacity_hours = greatest(coalesce(p_weekly_capacity_hours, m.weekly_capacity_hours, 0), 0),
      availability_status = coalesce(p_availability_status, m.availability_status),
      status = 'active',
      updated_at = now()
    where m.id = v_member_id;

    select m.role
      into v_role
    from public.members m
    where m.id = v_member_id;

  else
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
    returning id into v_member_id;

    v_role := 'member';
  end if;

  organization_id := v_org_id;
  member_id := v_member_id;
  role := v_role;
  return next;
end;
$$;

revoke all on function public.join_organization_by_invite_code(text, text, text, integer, public.availability_status_enum) from public;
grant execute on function public.join_organization_by_invite_code(text, text, text, integer, public.availability_status_enum) to authenticated;