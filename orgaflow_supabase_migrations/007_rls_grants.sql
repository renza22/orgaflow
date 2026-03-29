grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.members enable row level security;
alter table public.projects enable row level security;
alter table public.tasks enable row level security;
alter table public.member_skills enable row level security;
alter table public.portfolio_links enable row level security;
alter table public.task_assignments enable row level security;
alter table public.task_dependencies enable row level security;
alter table public.task_skill_requirements enable row level security;
alter table public.notifications enable row level security;
alter table public.fairness_scores enable row level security;
alter table public.rebalance_plans enable row level security;
alter table public.rebalance_items enable row level security;
alter table public.activity_logs enable row level security;

alter table public.organization_types enable row level security;
alter table public.study_programs enable row level security;
alter table public.position_templates enable row level security;
alter table public.division_templates enable row level security;
alter table public.portfolio_platforms enable row level security;
alter table public.skill_categories enable row level security;
alter table public.skills enable row level security;

-- Clean old policies if rerun
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND policyname IN (
        'organization_types_read_all',
        'study_programs_read_all',
        'position_templates_read_all',
        'division_templates_read_all',
        'portfolio_platforms_read_all',
        'skill_categories_read_all',
        'skills_read_all',
        'profiles_select_self_or_same_org',
        'profiles_update_own',
        'portfolio_links_manage_own',
        'organizations_select_member_or_creator',
        'organizations_update_owner_admin',
        'members_select_same_org',
        'members_update_self_or_admin',
        'member_skills_manage_own_or_admin',
        'projects_select_same_org',
        'projects_insert_same_org',
        'projects_update_delete_same_org',
        'tasks_select_same_org',
        'tasks_insert_same_org',
        'tasks_update_delete_same_org',
        'task_skill_requirements_same_org',
        'task_dependencies_same_org',
        'task_assignments_select_same_org',
        'task_assignments_insert_same_org',
        'task_assignments_update_delete_same_org',
        'notifications_read_own',
        'notifications_update_own',
        'fairness_scores_same_org',
        'rebalance_plans_same_org',
        'rebalance_items_same_org',
        'activity_logs_same_org'
      )
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
  END LOOP;
END $$;

-- Reference tables: authenticated read-only
create policy "organization_types_read_all"
on public.organization_types for select
to authenticated
using (true);

create policy "study_programs_read_all"
on public.study_programs for select
to authenticated
using (true);

create policy "position_templates_read_all"
on public.position_templates for select
to authenticated
using (true);

create policy "division_templates_read_all"
on public.division_templates for select
to authenticated
using (true);

create policy "portfolio_platforms_read_all"
on public.portfolio_platforms for select
to authenticated
using (true);

create policy "skill_categories_read_all"
on public.skill_categories for select
to authenticated
using (true);

create policy "skills_read_all"
on public.skills for select
to authenticated
using (true);

-- Profiles
create policy "profiles_select_self_or_same_org"
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or exists (
    select 1
    from public.members self_m
    join public.members target_m
      on self_m.organization_id = target_m.organization_id
    where self_m.profile_id = auth.uid()
      and self_m.status = 'active'
      and target_m.profile_id = profiles.id
      and target_m.status = 'active'
  )
);

create policy "profiles_update_own"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Portfolio links
create policy "portfolio_links_manage_own"
on public.portfolio_links for all
to authenticated
using (profile_id = auth.uid())
with check (profile_id = auth.uid());

-- Organizations
create policy "organizations_select_member_or_creator"
on public.organizations for select
to authenticated
using (created_by = auth.uid() or public.is_org_member(id));

create policy "organizations_update_owner_admin"
on public.organizations for update
to authenticated
using (
  exists (
    select 1 from public.members m
    where m.organization_id = organizations.id
      and m.profile_id = auth.uid()
      and m.status = 'active'
      and m.role in ('owner', 'admin')
  )
)
with check (
  exists (
    select 1 from public.members m
    where m.organization_id = organizations.id
      and m.profile_id = auth.uid()
      and m.status = 'active'
      and m.role in ('owner', 'admin')
  )
);

-- Members
create policy "members_select_same_org"
on public.members for select
to authenticated
using (public.is_org_member(organization_id));

create policy "members_update_self_or_admin"
on public.members for update
to authenticated
using (
  profile_id = auth.uid()
  or exists (
    select 1 from public.members m
    where m.organization_id = members.organization_id
      and m.profile_id = auth.uid()
      and m.status = 'active'
      and m.role in ('owner', 'admin')
  )
)
with check (
  profile_id = auth.uid()
  or exists (
    select 1 from public.members m
    where m.organization_id = members.organization_id
      and m.profile_id = auth.uid()
      and m.status = 'active'
      and m.role in ('owner', 'admin')
  )
);

-- Member skills
create policy "member_skills_manage_own_or_admin"
on public.member_skills for all
to authenticated
using (
  exists (
    select 1 from public.members m
    where m.id = member_skills.member_id
      and (
        m.profile_id = auth.uid()
        or exists (
          select 1 from public.members admin_m
          where admin_m.organization_id = m.organization_id
            and admin_m.profile_id = auth.uid()
            and admin_m.status = 'active'
            and admin_m.role in ('owner', 'admin')
        )
      )
  )
)
with check (
  exists (
    select 1 from public.members m
    where m.id = member_skills.member_id
      and (
        m.profile_id = auth.uid()
        or exists (
          select 1 from public.members admin_m
          where admin_m.organization_id = m.organization_id
            and admin_m.profile_id = auth.uid()
            and admin_m.status = 'active'
            and admin_m.role in ('owner', 'admin')
        )
      )
  )
);

-- Projects
create policy "projects_select_same_org"
on public.projects for select
to authenticated
using (public.is_org_member(organization_id));

create policy "projects_insert_same_org"
on public.projects for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.is_org_member(organization_id)
);

create policy "projects_update_delete_same_org"
on public.projects for update
to authenticated
using (public.is_org_member(organization_id))
with check (public.is_org_member(organization_id));

create policy "projects_update_delete_same_org_delete"
on public.projects for delete
to authenticated
using (public.is_org_member(organization_id));

-- Tasks
create policy "tasks_select_same_org"
on public.tasks for select
to authenticated
using (
  exists (
    select 1
    from public.projects p
    where p.id = tasks.project_id
      and public.is_org_member(p.organization_id)
  )
);

create policy "tasks_insert_same_org"
on public.tasks for insert
to authenticated
with check (
  created_by = auth.uid()
  and exists (
    select 1
    from public.projects p
    where p.id = tasks.project_id
      and public.is_org_member(p.organization_id)
  )
);

create policy "tasks_update_delete_same_org"
on public.tasks for update
to authenticated
using (
  exists (
    select 1
    from public.projects p
    where p.id = tasks.project_id
      and public.is_org_member(p.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.projects p
    where p.id = tasks.project_id
      and public.is_org_member(p.organization_id)
  )
);

create policy "tasks_update_delete_same_org_delete"
on public.tasks for delete
to authenticated
using (
  exists (
    select 1
    from public.projects p
    where p.id = tasks.project_id
      and public.is_org_member(p.organization_id)
  )
);

-- Task skill requirements
create policy "task_skill_requirements_same_org"
on public.task_skill_requirements for all
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_skill_requirements.task_id
      and public.is_org_member(p.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_skill_requirements.task_id
      and public.is_org_member(p.organization_id)
  )
);

-- Task dependencies
create policy "task_dependencies_same_org"
on public.task_dependencies for all
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_dependencies.task_id
      and public.is_org_member(p.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_dependencies.task_id
      and public.is_org_member(p.organization_id)
  )
);

-- Task assignments
create policy "task_assignments_select_same_org"
on public.task_assignments for select
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_assignments.task_id
      and public.is_org_member(p.organization_id)
  )
);

create policy "task_assignments_insert_same_org"
on public.task_assignments for insert
to authenticated
with check (
  (assigned_by is null or assigned_by = auth.uid())
  and exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_assignments.task_id
      and public.is_org_member(p.organization_id)
  )
  and exists (
    select 1
    from public.members target_m
    join public.tasks t on t.id = task_assignments.task_id
    join public.projects p on p.id = t.project_id
    where target_m.id = task_assignments.member_id
      and target_m.organization_id = p.organization_id
  )
);

create policy "task_assignments_update_delete_same_org"
on public.task_assignments for update
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_assignments.task_id
      and public.is_org_member(p.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_assignments.task_id
      and public.is_org_member(p.organization_id)
  )
);

create policy "task_assignments_update_delete_same_org_delete"
on public.task_assignments for delete
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_assignments.task_id
      and public.is_org_member(p.organization_id)
  )
);

-- Notifications
create policy "notifications_read_own"
on public.notifications for select
to authenticated
using (
  exists (
    select 1 from public.members m
    where m.id = notifications.recipient_member_id
      and m.profile_id = auth.uid()
  )
);

create policy "notifications_update_own"
on public.notifications for update
to authenticated
using (
  exists (
    select 1 from public.members m
    where m.id = notifications.recipient_member_id
      and m.profile_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.members m
    where m.id = notifications.recipient_member_id
      and m.profile_id = auth.uid()
  )
);

-- Fairness scores
create policy "fairness_scores_same_org"
on public.fairness_scores for select
to authenticated
using (
  exists (
    select 1
    from public.members target_m
    where target_m.id = fairness_scores.member_id
      and public.is_org_member(target_m.organization_id)
  )
);

-- Rebalance plans and items
create policy "rebalance_plans_same_org"
on public.rebalance_plans for all
to authenticated
using (public.is_org_member(organization_id))
with check (public.is_org_member(organization_id) and created_by = auth.uid());

create policy "rebalance_items_same_org"
on public.rebalance_items for all
to authenticated
using (
  exists (
    select 1 from public.rebalance_plans rp
    where rp.id = rebalance_items.plan_id
      and public.is_org_member(rp.organization_id)
  )
)
with check (
  exists (
    select 1 from public.rebalance_plans rp
    where rp.id = rebalance_items.plan_id
      and public.is_org_member(rp.organization_id)
  )
);

-- Activity logs
create policy "activity_logs_same_org"
on public.activity_logs for select
to authenticated
using (
  (organization_id is null and actor_user_id = auth.uid())
  or (organization_id is not null and public.is_org_member(organization_id))
);

-- View grants
grant select on public.v_member_workload to authenticated;
