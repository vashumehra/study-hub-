-- STUDY HUB shared content setup
-- Run this entire file in Supabase SQL Editor.

create table if not exists public.study_content (
  id uuid primary key default gen_random_uuid(),
  content_type text not null check (content_type in ('pdf','note','video')),
  class_name text not null check (class_name in ('5','6','7','8','9','10','11','12','college')),
  board text not null default 'CBSE',
  medium text not null default 'Hindi',
  stream text not null default 'All',
  subject text not null,
  title text not null,
  description text not null default '',
  file_path text,
  video_url text,
  mime_type text,
  file_size bigint,
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  constraint study_content_source_check check (
    (content_type in ('pdf','note') and file_path is not null and video_url is null)
    or (content_type='video' and video_url is not null and file_path is null)
  )
);

alter table public.study_content enable row level security;

drop policy if exists "Students can read published content" on public.study_content;
create policy "Students can read published content"
on public.study_content for select to anon, authenticated
using (true);

drop policy if exists "Admins can add study content" on public.study_content;
create policy "Admins can add study content"
on public.study_content for insert to authenticated
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "Admins can update study content" on public.study_content;
create policy "Admins can update study content"
on public.study_content for update to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "Admins can delete study content" on public.study_content;
create policy "Admins can delete study content"
on public.study_content for delete to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('study-content', 'study-content', true, 20971520,
  array['application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
on conflict (id) do update set public=true, file_size_limit=20971520,
  allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "Admins can upload study files" on storage.objects;
create policy "Admins can upload study files"
on storage.objects for insert to authenticated
with check (
  bucket_id='study-content'
  and exists (select 1 from public.admin_users a where a.user_id=auth.uid())
);

drop policy if exists "Admins can update study files" on storage.objects;
create policy "Admins can update study files"
on storage.objects for update to authenticated
using (bucket_id='study-content' and exists (select 1 from public.admin_users a where a.user_id=auth.uid()))
with check (bucket_id='study-content' and exists (select 1 from public.admin_users a where a.user_id=auth.uid()));

drop policy if exists "Admins can delete study files" on storage.objects;
create policy "Admins can delete study files"
on storage.objects for delete to authenticated
using (bucket_id='study-content' and exists (select 1 from public.admin_users a where a.user_id=auth.uid()));
