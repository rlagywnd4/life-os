-- PostgreSQL makes a newly added enum value visible only after this migration
-- commits. Keep this separate from the schema that uses DRAFT / WAITING.
alter type public.project_status add value if not exists 'DRAFT' before 'ACTIVE';
alter type public.action_status add value if not exists 'WAITING' before 'DONE';
