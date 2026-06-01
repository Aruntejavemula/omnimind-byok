-- Omnimind BYOK / Mio MVP Supabase schema
-- API keys should NOT be stored here. Keep provider keys in device secure storage.

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text not null default 'Personal',
  instructions text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  title text not null default 'New chat',
  provider_id text not null default 'openai',
  model text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid references public.chats(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text not null check (role in ('system', 'user', 'assistant')),
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.provider_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  provider_id text not null,
  enabled boolean not null default true,
  default_model text not null default '',
  key_fingerprint text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, provider_id)
);

alter table public.projects enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.provider_settings enable row level security;

create policy "projects_owner_all" on public.projects for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "chats_owner_all" on public.chats for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "messages_owner_all" on public.messages for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "provider_settings_owner_all" on public.provider_settings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_chats_user_updated on public.chats(user_id, updated_at desc);
create index if not exists idx_messages_chat_created on public.messages(chat_id, created_at asc);
