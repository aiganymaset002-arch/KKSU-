-- KKSU Online — схема базы данных Supabase
-- Выполните этот файл целиком в Supabase: SQL Editor → New query → Run.
--
-- Модель данных:
--   kksu_members  — участники школы: роль, подтверждение, блокировка (связь с auth.users)
--   kksu_records  — записи приложения (задания, работы, оценки, сообщения, проекты…)
--                   в виде JSON; для каждой записи хранится список тех, кому она видна.
-- Правила доступа (RLS) гарантируют, что каждый видит только свои данные:
--   • сотрудники (педагог, психолог, эксперт, наставник, администратор) после подтверждения
--     администратором видят данные школы;
--   • ученик, родитель, партнёр видят записи, где они есть в visible_to, и общие записи школы.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Участники
-- ---------------------------------------------------------------------------
create table if not exists public.kksu_members (
    user_id     uuid primary key references auth.users (id) on delete cascade,
    school_id   text not null default 'kksu',
    role        text not null check (role in ('student','parent','teacher','psychologist','expert','mentor','partner','admin')),
    full_name   text not null default '',
    approved    boolean not null default false,
    blocked     boolean not null default false,
    created_at  timestamptz not null default now()
);

alter table public.kksu_members enable row level security;

-- Роль текущего пользователя (security definer — чтобы политики не зацикливались)
create or replace function public.kksu_my_role() returns text
language sql stable security definer set search_path = public as $$
    select role from public.kksu_members
    where user_id = auth.uid() and approved and not blocked
$$;

create or replace function public.kksu_my_school() returns text
language sql stable security definer set search_path = public as $$
    select school_id from public.kksu_members where user_id = auth.uid() and not blocked
$$;

create or replace function public.kksu_is_staff() returns boolean
language sql stable security definer set search_path = public as $$
    select coalesce(public.kksu_my_role() in ('teacher','psychologist','expert','mentor','admin'), false)
$$;

create or replace function public.kksu_is_admin() returns boolean
language sql stable security definer set search_path = public as $$
    select coalesce(public.kksu_my_role() = 'admin', false)
$$;

-- Ученики, родители и партнёры подтверждаются автоматически,
-- сотрудники — только администратором (чтобы никто не назначил себя педагогом или админом).
create or replace function public.kksu_member_defaults() returns trigger
language plpgsql security definer set search_path = public as $$
begin
    if tg_op = 'INSERT' then
        new.approved := new.role in ('student','parent','partner');
        new.blocked := false;
        -- Первый участник школы становится подтверждённым администратором
        if not exists (select 1 from public.kksu_members where school_id = new.school_id) then
            new.role := 'admin';
            new.approved := true;
        end if;
    end if;
    return new;
end $$;

drop trigger if exists kksu_member_defaults on public.kksu_members;
create trigger kksu_member_defaults before insert on public.kksu_members
for each row execute function public.kksu_member_defaults();

drop policy if exists "members: read school" on public.kksu_members;
create policy "members: read school" on public.kksu_members for select
    using (user_id = auth.uid() or school_id = public.kksu_my_school());

drop policy if exists "members: register self" on public.kksu_members;
create policy "members: register self" on public.kksu_members for insert
    with check (user_id = auth.uid());

drop policy if exists "members: admin manage" on public.kksu_members;
create policy "members: admin manage" on public.kksu_members for all
    using (public.kksu_is_admin() and school_id = public.kksu_my_school())
    with check (public.kksu_is_admin() and school_id = public.kksu_my_school());

-- ---------------------------------------------------------------------------
-- Записи приложения
-- ---------------------------------------------------------------------------
create table if not exists public.kksu_records (
    collection  text not null,
    id          uuid not null,
    school_id   text not null default 'kksu',
    owner_id    uuid,
    visible_to  uuid[] not null default '{}',
    data        jsonb not null,
    deleted     boolean not null default false,
    updated_at  timestamptz not null default now(),
    primary key (collection, id)
);

create index if not exists kksu_records_updated on public.kksu_records (school_id, updated_at);
create index if not exists kksu_records_visible on public.kksu_records using gin (visible_to);

alter table public.kksu_records enable row level security;

create or replace function public.kksu_touch() returns trigger language plpgsql as $$
begin
    new.updated_at := now();
    return new;
end $$;

drop trigger if exists kksu_touch on public.kksu_records;
create trigger kksu_touch before insert or update on public.kksu_records
for each row execute function public.kksu_touch();

-- Коллекции, в которых участники сами записываются в общие записи
-- (запись на курс, в международный класс, в команду, лайк на выставке).
create or replace function public.kksu_is_joinable(c text) returns boolean
language sql immutable as $$
    select c in ('globalClasses','engineeringCourses','teacherCourses','teams','challenges','projects','internationalProjects')
$$;

-- Коллекции, которые может менять только персонал (доступы, цены, промокоды, настройки оплаты).
create or replace function public.kksu_is_staff_only(c text) returns boolean
language sql immutable as $$
    select c in ('entitlements','products','promoCodes','billingSettings','programs','partners','internships','events')
$$;

drop policy if exists "records: read" on public.kksu_records;
create policy "records: read" on public.kksu_records for select
    using (school_id = public.kksu_my_school()
           and (public.kksu_is_staff()
                or owner_id = auth.uid()
                or auth.uid() = any (visible_to)
                or visible_to = '{}'));

drop policy if exists "records: insert" on public.kksu_records;
create policy "records: insert" on public.kksu_records for insert
    with check (school_id = public.kksu_my_school()
                and (public.kksu_is_staff()
                     or (owner_id = auth.uid() and not public.kksu_is_staff_only(collection))));

drop policy if exists "records: update" on public.kksu_records;
create policy "records: update" on public.kksu_records for update
    using (school_id = public.kksu_my_school()
           and (public.kksu_is_staff()
                or (not public.kksu_is_staff_only(collection)
                    and (owner_id = auth.uid()
                         or auth.uid() = any (visible_to)
                         or public.kksu_is_joinable(collection)))))
    with check (school_id = public.kksu_my_school()
                and (public.kksu_is_staff() or not public.kksu_is_staff_only(collection)));

-- Удаление — через флаг deleted (update); физически удаляет только администратор.
drop policy if exists "records: admin delete" on public.kksu_records;
create policy "records: admin delete" on public.kksu_records for delete
    using (public.kksu_is_admin() and school_id = public.kksu_my_school());

-- ---------------------------------------------------------------------------
-- Удаление аккаунта самим пользователем (App Store 5.1.1(v))
-- ---------------------------------------------------------------------------
create or replace function public.kksu_delete_my_account() returns void
language plpgsql security definer set search_path = public as $$
begin
    update public.kksu_records set deleted = true, data = '{}'::jsonb
        where owner_id = auth.uid() or (collection = 'users' and id = auth.uid());
    delete from auth.users where id = auth.uid();
end $$;

grant execute on function public.kksu_delete_my_account() to authenticated;
