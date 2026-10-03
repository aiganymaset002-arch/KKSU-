-- ATA MURA — схема базы данных Supabase
-- Выполните этот файл целиком: Supabase → SQL Editor → New query → Run.
-- Можно в том же проекте, что и KKSU: таблицы ATA MURA называются atamura_* и не пересекаются с kksu_*.
--
-- Модель данных:
--   atamura_members — участники: роль (member / editor / admin) и блокировка
--   atamura_records — записи приложения (публикации, проекты, музей, курсы, новости…) в JSON.
--                     published = видно всем; иначе — автору, адресатам (visible_to) и редакции.
-- Правила доступа (RLS):
--   • опубликованное читают все вошедшие участники;
--   • неопубликованное (модерация, заказы, черновики) — автор, адресаты и редакция;
--   • участник меняет только свои записи; редакционные разделы (новости, журнал, курсы,
--     Creator Studio) меняют только редакторы и администраторы;
--   • участник не может сам «одобрить» публикацию или «оплатить» заказ — это делает триггер.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Участники
-- ---------------------------------------------------------------------------
create table if not exists public.atamura_members (
    user_id     uuid primary key references auth.users (id) on delete cascade,
    role        text not null default 'member' check (role in ('member', 'editor', 'admin')),
    full_name   text not null default '',
    blocked     boolean not null default false,
    created_at  timestamptz not null default now()
);

alter table public.atamura_members enable row level security;

create or replace function public.atamura_my_role() returns text
language sql stable security definer set search_path = public as $$
    select role from public.atamura_members where user_id = auth.uid() and not blocked
$$;

create or replace function public.atamura_is_staff() returns boolean
language sql stable security definer set search_path = public as $$
    select coalesce(public.atamura_my_role() in ('editor', 'admin'), false)
$$;

create or replace function public.atamura_is_admin() returns boolean
language sql stable security definer set search_path = public as $$
    select coalesce(public.atamura_my_role() = 'admin', false)
$$;

create or replace function public.atamura_is_member() returns boolean
language sql stable security definer set search_path = public as $$
    select public.atamura_my_role() is not null
$$;

-- Новый участник всегда member; самый первый участник становится администратором.
create or replace function public.atamura_member_defaults() returns trigger
language plpgsql security definer set search_path = public as $$
begin
    if tg_op = 'INSERT' then
        new.role := 'member';
        new.blocked := false;
        if not exists (select 1 from public.atamura_members) then
            new.role := 'admin';
        end if;
    end if;
    return new;
end $$;

drop trigger if exists atamura_member_defaults on public.atamura_members;
create trigger atamura_member_defaults before insert on public.atamura_members
for each row execute function public.atamura_member_defaults();

drop policy if exists "members: read" on public.atamura_members;
create policy "members: read" on public.atamura_members for select
    using (user_id = auth.uid() or public.atamura_is_member());

drop policy if exists "members: register self" on public.atamura_members;
create policy "members: register self" on public.atamura_members for insert
    with check (user_id = auth.uid());

drop policy if exists "members: admin manage" on public.atamura_members;
create policy "members: admin manage" on public.atamura_members for update
    using (public.atamura_is_admin())
    with check (public.atamura_is_admin());

-- ---------------------------------------------------------------------------
-- Записи приложения
-- ---------------------------------------------------------------------------
create table if not exists public.atamura_records (
    collection  text not null,
    id          uuid not null,
    owner_id    uuid,
    visible_to  uuid[] not null default '{}',
    published   boolean not null default false,
    data        jsonb not null,
    deleted     boolean not null default false,
    updated_at  timestamptz not null default now(),
    primary key (collection, id)
);

create index if not exists atamura_records_updated on public.atamura_records (updated_at);
create index if not exists atamura_records_visible on public.atamura_records using gin (visible_to);

alter table public.atamura_records enable row level security;

-- Разделы, которые меняет только редакция.
create or replace function public.atamura_is_staff_only(c text) returns boolean
language sql immutable as $$
    select c in ('topics', 'forgottenIdeas', 'kidsThemes', 'news', 'magazines', 'courses', 'products',
                 'contentItems', 'ideas', 'vlog', 'guests', 'series', 'media', 'events', 'partners',
                 'tasks', 'settings')
$$;

-- Разделы, где участник создаёт запись для другого человека (уведомление, приглашение).
create or replace function public.atamura_is_shared_write(c text) returns boolean
language sql immutable as $$
    select c in ('notifications', 'invites')
$$;

-- Разделы с модерацией: публикует только редакция.
create or replace function public.atamura_is_moderated(c text) returns boolean
language sql immutable as $$
    select c in ('posts', 'places', 'projects', 'museum', 'kidsWorks', 'research')
$$;

create or replace function public.atamura_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
    new.updated_at := now();
    if not public.atamura_is_staff() then
        -- Участник не может сам опубликовать материал, который проходит модерацию.
        if public.atamura_is_moderated(new.collection) then
            if tg_op = 'INSERT' or not old.published then
                new.published := false;
                new.data := jsonb_set(new.data, '{status}', '"pending"', true);
                if new.collection = 'research' then
                    new.data := jsonb_set(new.data, '{reviewStatus}',
                        to_jsonb(case when new.data->>'reviewStatus' in ('draft', 'submitted') then new.data->>'reviewStatus' else 'draft' end), true);
                end if;
            end if;
        end if;
        -- Заказ участник создаёт только «ожидающим оплаты».
        if new.collection = 'orders' then
            if tg_op = 'INSERT' then
                new.data := jsonb_set(new.data, '{status}', '"pending"', true);
            elsif old.data->>'status' is distinct from new.data->>'status' then
                new.data := jsonb_set(new.data, '{status}', to_jsonb(old.data->>'status'), true);
            end if;
        end if;
        -- Записаться самостоятельно можно только на бесплатный курс.
        if new.collection = 'enrollments' and tg_op = 'INSERT' then
            if not exists (
                select 1 from public.atamura_records c
                where c.collection = 'courses' and c.id = (new.data->>'courseId')::uuid
                  and (c.data->>'access' = 'free' or coalesce((c.data->>'price')::int, 0) = 0
                       or c.data->>'access' = 'membersOnly')
            ) then
                raise exception 'paid course requires a confirmed order';
            end if;
        end if;
        -- Роль и баллы в профиле меняет только редакция.
        if new.collection = 'users' and tg_op = 'UPDATE' then
            new.data := jsonb_set(new.data, '{role}', coalesce(old.data->'role', '"member"'), true);
        end if;
    end if;
    return new;
end $$;

drop trigger if exists atamura_guard on public.atamura_records;
create trigger atamura_guard before insert or update on public.atamura_records
for each row execute function public.atamura_guard();

drop policy if exists "records: read" on public.atamura_records;
create policy "records: read" on public.atamura_records for select
    using (public.atamura_is_member()
           and (published
                or public.atamura_is_staff()
                or owner_id = auth.uid()
                or auth.uid() = any (visible_to)));

drop policy if exists "records: insert" on public.atamura_records;
create policy "records: insert" on public.atamura_records for insert
    with check (public.atamura_is_staff()
                or (public.atamura_is_member()
                    and not public.atamura_is_staff_only(collection)
                    and (owner_id = auth.uid()
                         or (public.atamura_is_shared_write(collection) and owner_id is null))));

drop policy if exists "records: update" on public.atamura_records;
create policy "records: update" on public.atamura_records for update
    using (public.atamura_is_staff()
           or (public.atamura_is_member()
               and not public.atamura_is_staff_only(collection)
               and (owner_id = auth.uid()
                    or (public.atamura_is_shared_write(collection) and auth.uid() = any (visible_to)))))
    with check (public.atamura_is_staff()
                or (not public.atamura_is_staff_only(collection)
                    and (owner_id = auth.uid()
                         or (public.atamura_is_shared_write(collection) and auth.uid() = any (visible_to)))));

-- Удаление — через флаг deleted (update); физически удаляет только администратор.
drop policy if exists "records: admin delete" on public.atamura_records;
create policy "records: admin delete" on public.atamura_records for delete
    using (public.atamura_is_admin());

-- ---------------------------------------------------------------------------
-- Удаление аккаунта самим пользователем (App Store 5.1.1(v))
-- ---------------------------------------------------------------------------
create or replace function public.atamura_delete_my_account() returns void
language plpgsql security definer set search_path = public as $$
begin
    update public.atamura_records set deleted = true, data = '{}'::jsonb, published = false
        where owner_id = auth.uid() or (collection = 'users' and id = auth.uid());
    delete from public.atamura_members where user_id = auth.uid();
    delete from auth.users where id = auth.uid();
end $$;

grant execute on function public.atamura_delete_my_account() to authenticated;
