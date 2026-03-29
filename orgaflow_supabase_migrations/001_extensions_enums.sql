create extension if not exists pgcrypto;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'member_role_enum') THEN
    CREATE TYPE public.member_role_enum AS ENUM ('owner', 'admin', 'member');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'member_status_enum') THEN
    CREATE TYPE public.member_status_enum AS ENUM ('pending', 'active', 'inactive', 'left');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'availability_status_enum') THEN
    CREATE TYPE public.availability_status_enum AS ENUM ('available', 'unavailable');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'project_status_enum') THEN
    CREATE TYPE public.project_status_enum AS ENUM ('draft', 'active', 'on_hold', 'completed', 'cancelled');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status_enum') THEN
    CREATE TYPE public.task_status_enum AS ENUM ('backlog', 'todo', 'in_progress', 'in_review', 'done', 'blocked', 'cancelled');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_priority_enum') THEN
    CREATE TYPE public.task_priority_enum AS ENUM ('low', 'medium', 'high', 'critical');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type_enum') THEN
    CREATE TYPE public.notification_type_enum AS ENUM ('assignment', 'dependency', 'rebalance', 'system');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rebalance_plan_status_enum') THEN
    CREATE TYPE public.rebalance_plan_status_enum AS ENUM ('draft', 'proposed', 'approved', 'applied', 'cancelled');
  END IF;
END $$;
