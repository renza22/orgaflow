-- OPTIONAL / DESTRUCTIVE
-- Run this ONLY if you want to wipe the existing Orgaflow objects in the current Supabase project.
-- Always make a backup first.

-- Drop views first
DROP VIEW IF EXISTS public.v_member_workload;

-- Drop triggers on auth/users and public tables if they exist
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') THEN
    EXECUTE 'DROP TRIGGER on_auth_user_created ON auth.users';
  END IF;
END $$;

-- Drop functions that may depend on tables
DROP FUNCTION IF EXISTS public.join_organization_by_invite_code(text, text, text, integer, public.availability_status_enum);
DROP FUNCTION IF EXISTS public.create_organization_with_owner(text, text, text, text, text, integer, public.availability_status_enum);
DROP FUNCTION IF EXISTS public.generate_invite_code(text);
DROP FUNCTION IF EXISTS public.is_org_member(uuid);
DROP FUNCTION IF EXISTS public.validate_task_dependency_same_project();
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.slugify(text);
DROP FUNCTION IF EXISTS public.set_updated_at();

-- Drop tables in dependency order
DROP TABLE IF EXISTS public.activity_logs CASCADE;
DROP TABLE IF EXISTS public.rebalance_items CASCADE;
DROP TABLE IF EXISTS public.rebalance_plans CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.fairness_scores CASCADE;
DROP TABLE IF EXISTS public.task_assignments CASCADE;
DROP TABLE IF EXISTS public.task_dependencies CASCADE;
DROP TABLE IF EXISTS public.task_skill_requirements CASCADE;
DROP TABLE IF EXISTS public.tasks CASCADE;
DROP TABLE IF EXISTS public.projects CASCADE;
DROP TABLE IF EXISTS public.member_skills CASCADE;
DROP TABLE IF EXISTS public.skills CASCADE;
DROP TABLE IF EXISTS public.members CASCADE;
DROP TABLE IF EXISTS public.portfolio_links CASCADE;
DROP TABLE IF EXISTS public.organizations CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.skill_categories CASCADE;
DROP TABLE IF EXISTS public.portfolio_platforms CASCADE;
DROP TABLE IF EXISTS public.division_templates CASCADE;
DROP TABLE IF EXISTS public.position_templates CASCADE;
DROP TABLE IF EXISTS public.study_programs CASCADE;
DROP TABLE IF EXISTS public.organization_types CASCADE;

-- Drop enums last
DROP TYPE IF EXISTS public.rebalance_plan_status_enum CASCADE;
DROP TYPE IF EXISTS public.notification_type_enum CASCADE;
DROP TYPE IF EXISTS public.task_priority_enum CASCADE;
DROP TYPE IF EXISTS public.task_status_enum CASCADE;
DROP TYPE IF EXISTS public.project_status_enum CASCADE;
DROP TYPE IF EXISTS public.availability_status_enum CASCADE;
DROP TYPE IF EXISTS public.member_status_enum CASCADE;
DROP TYPE IF EXISTS public.member_role_enum CASCADE;
