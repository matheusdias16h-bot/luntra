create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(), name text not null unique,
  slug text not null unique, description text not null default '', image_url text,
  active boolean not null default true, sort_order integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.platforms (
  id uuid primary key default gen_random_uuid(), name text not null unique,
  slug text not null unique, active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
  short_description text not null default '', description text not null default '', image_url text,
  category_id uuid references public.categories(id) on delete restrict,
  platform_id uuid references public.platforms(id) on delete restrict,
  price numeric(10,2) not null default 0 check(price >= 0), old_price numeric(10,2) check(old_price is null or old_price >= 0),
  currency char(3) not null default 'BRL', level text not null default 'Todos os níveis',
  duration text, lessons_count integer check(lessons_count is null or lessons_count >= 0),
  certificate boolean not null default false, producer_name text,
  affiliate_url text not null check(affiliate_url ~ '^https?://'),
  active boolean not null default false, featured boolean not null default false,
  sort_order integer not null default 0, seo_title text, seo_description text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.clicks (
  id bigint generated always as identity primary key,
  course_id uuid not null references public.courses(id) on delete cascade,
  created_at timestamptz not null default now(), page text,
  referrer text, utm_source text, utm_medium text, utm_campaign text, utm_content text, utm_term text
);
create index if not exists clicks_course_date_idx on public.clicks(course_id, created_at desc);
create index if not exists courses_public_order_idx on public.courses(active, sort_order, created_at desc);

alter table public.admin_users enable row level security;
alter table public.categories enable row level security;
alter table public.platforms enable row level security;
alter table public.courses enable row level security;
alter table public.clicks enable row level security;

create policy "admin reads own membership" on public.admin_users for select to authenticated using ((select auth.uid()) = user_id);
create policy "public reads active categories" on public.categories for select to anon, authenticated using (active or exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));
create policy "admins manage categories" on public.categories for all to authenticated using (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid()))) with check (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));
create policy "public reads active platforms" on public.platforms for select to anon, authenticated using (active or exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));
create policy "admins manage platforms" on public.platforms for all to authenticated using (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid()))) with check (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));
create policy "public reads active courses" on public.courses for select to anon using (active);
create policy "authenticated reads active or admin courses" on public.courses for select to authenticated using (active or exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));
create policy "admins insert courses" on public.courses for insert to authenticated with check (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));
create policy "admins update courses" on public.courses for update to authenticated using (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid()))) with check (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));
create policy "admins delete courses" on public.courses for delete to authenticated using (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));
create policy "admins read clicks" on public.clicks for select to authenticated using (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));

revoke all on public.admin_users, public.categories, public.platforms, public.courses, public.clicks from anon, authenticated;
grant select on public.admin_users to anon, authenticated;
grant select on public.categories, public.platforms to anon, authenticated;
grant insert, update, delete on public.categories, public.platforms to authenticated;
grant select (id,name,slug,short_description,description,image_url,category_id,platform_id,price,old_price,currency,level,duration,lessons_count,certificate,producer_name,active,featured,sort_order,seo_title,seo_description,created_at,updated_at) on public.courses to anon;
grant select on public.courses to authenticated;
grant insert, update, delete on public.courses to authenticated;
grant select on public.clicks to authenticated;

create or replace function public.track_course_click(
  p_slug text, p_page text default null, p_referrer text default null,
  p_utm_source text default null, p_utm_medium text default null,
  p_utm_campaign text default null, p_utm_content text default null, p_utm_term text default null
) returns text language plpgsql security definer set search_path = '' as $$
declare course_row public.courses%rowtype;
begin
  select * into course_row from public.courses where slug=p_slug and active=true;
  if not found then return null; end if;
  insert into public.clicks(course_id,page,referrer,utm_source,utm_medium,utm_campaign,utm_content,utm_term)
  values(course_row.id,left(p_page,500),left(p_referrer,1000),left(p_utm_source,200),left(p_utm_medium,200),left(p_utm_campaign,200),left(p_utm_content,200),left(p_utm_term,200));
  return course_row.affiliate_url;
end;
$$;
revoke all on function public.track_course_click(text,text,text,text,text,text,text,text) from public;
grant execute on function public.track_course_click(text,text,text,text,text,text,text,text) to anon, authenticated;

insert into public.categories(name,slug,sort_order) values
('Marketing','marketing',1),('Tecnologia','tecnologia',2),('Programação','programacao',3),('Design','design',4),
('Inteligência Artificial','inteligencia-artificial',5),('Finanças','financas',6),('Negócios','negocios',7),
('Desenvolvimento Pessoal','desenvolvimento-pessoal',8),('Idiomas','idiomas',9),('Vendas','vendas',10),('Fotografia','fotografia',11),('Edição de Vídeo','edicao-de-video',12)
on conflict(slug) do nothing;
insert into public.platforms(name,slug) values('Hotmart','hotmart'),('Kiwify','kiwify'),('Kirvano','kirvano'),('Eduzz','eduzz'),('Outras','outras') on conflict(slug) do nothing;

-- Bootstrap one administrator after creating the account in Supabase Auth:
-- insert into public.admin_users(user_id) values ('AUTH_USER_UUID');

