-- Ruby World schema. Run once in Supabase > SQL Editor.
create table profiles (id uuid primary key references auth.users(id) on delete cascade, username text unique not null check (char_length(username) between 3 and 20), display_name text, avatar_url text, bio text default '', created_at timestamptz default now());
create table levels (id uuid primary key default gen_random_uuid(), creator_id uuid not null default auth.uid() references profiles(id) on delete cascade, title text not null check (char_length(title) between 1 and 60), description text default '', level_data jsonb not null, thumbnail_url text, difficulty smallint default 1 check (difficulty between 1 and 5), published boolean not null default false, created_at timestamptz default now(), updated_at timestamptz default now());
create table level_likes (level_id uuid references levels(id) on delete cascade, user_id uuid default auth.uid() references profiles(id) on delete cascade, created_at timestamptz default now(), primary key (level_id, user_id));
create table level_favorites (level_id uuid references levels(id) on delete cascade, user_id uuid default auth.uid() references profiles(id) on delete cascade, created_at timestamptz default now(), primary key (level_id, user_id));
create table level_plays (id bigint generated always as identity primary key, level_id uuid not null references levels(id) on delete cascade, user_id uuid default auth.uid() references profiles(id) on delete cascade, played_at timestamptz default now());
create table level_completions (id bigint generated always as identity primary key, level_id uuid not null references levels(id) on delete cascade, user_id uuid not null default auth.uid() references profiles(id) on delete cascade, completion_time numeric not null check (completion_time >= 1 and completion_time < 36000), completed_at timestamptz default now());

-- Auto-create a profile when someone signs up.
create function handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin insert into profiles (id, username) values (new.id, coalesce(new.raw_user_meta_data->>'username', 'player_' || substr(new.id::text, 1, 8))); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();
create function touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end $$;
create trigger levels_touch before update on levels for each row execute function touch_updated_at();

alter table profiles enable row level security; alter table levels enable row level security; alter table level_likes enable row level security;
alter table level_favorites enable row level security; alter table level_plays enable row level security; alter table level_completions enable row level security;

-- Anyone can read profiles; you can only edit your own.
create policy "profiles readable" on profiles for select using (true);
create policy "edit own profile" on profiles for update using (id = auth.uid()) with check (id = auth.uid());
-- Published levels are public; drafts are visible only to their creator. Only creators change their own levels.
create policy "read published or own" on levels for select using (published or creator_id = auth.uid());
create policy "create own" on levels for insert with check (creator_id = auth.uid());
create policy "update own" on levels for update using (creator_id = auth.uid()) with check (creator_id = auth.uid());
create policy "delete own" on levels for delete using (creator_id = auth.uid());
-- Likes: public to read; you can only add/remove your own, on published levels.
create policy "likes readable" on level_likes for select using (true);
create policy "like as me" on level_likes for insert with check (user_id = auth.uid() and exists (select 1 from levels where id = level_id and published));
create policy "unlike as me" on level_likes for delete using (user_id = auth.uid());
-- Favorites are private to you.
create policy "own favorites read" on level_favorites for select using (user_id = auth.uid());
create policy "favorite as me" on level_favorites for insert with check (user_id = auth.uid());
create policy "unfavorite as me" on level_favorites for delete using (user_id = auth.uid());
-- Plays/completions: insert-only as yourself. No update/delete policy, so counts cannot be edited from the browser.
create policy "log own play" on level_plays for insert with check (user_id = auth.uid());
create policy "completions readable" on level_completions for select using (true);
create policy "log own completion" on level_completions for insert with check (user_id = auth.uid());

-- Stats are calculated, never stored, so they cannot be faked.
create view level_stats as select l.id as level_id,
 (select count(*) from level_likes x where x.level_id = l.id) as likes,
 (select count(*) from level_favorites x where x.level_id = l.id) as favorites,
 (select count(*) from level_plays x where x.level_id = l.id) as plays,
 (select count(*) from level_completions x where x.level_id = l.id) as completions,
 (select min(completion_time) from level_completions x where x.level_id = l.id) as best_time
from levels l where l.published;
grant select on level_stats to anon, authenticated;
