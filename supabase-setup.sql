-- ავტონაწილების მარაგის მონაცემთა ბაზა. გაუშვით Supabase SQL Editor-ში.
create extension if not exists pgcrypto;

create table if not exists public.team_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  role text not null default 'employee' check (role in ('owner','employee')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.parts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sku text,
  fitment text,
  location text,
  quantity integer not null default 0 check (quantity >= 0),
  cost_price numeric(12,2) not null default 0 check (cost_price >= 0),
  sale_price numeric(12,2) not null default 0 check (sale_price >= 0),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  part_id uuid references public.parts(id) on delete set null,
  part_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  unit_cost numeric(12,2) not null check (unit_cost >= 0),
  sold_by uuid references auth.users(id) on delete set null,
  sold_by_email text,
  sold_at timestamptz not null default now()
);

create or replace function public.is_active_member()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.team_members tm where tm.user_id = (select auth.uid()) and tm.active = true); $$;
create or replace function public.is_owner()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.team_members tm where tm.user_id = (select auth.uid()) and tm.active = true and tm.role = 'owner'); $$;

alter table public.team_members enable row level security;
alter table public.parts enable row level security;
alter table public.sales enable row level security;

drop policy if exists "members read own or owner reads team" on public.team_members;
create policy "members read own or owner reads team" on public.team_members for select to authenticated using (user_id = (select auth.uid()) or (select public.is_owner()));
drop policy if exists "owners add team members" on public.team_members;
create policy "owners add team members" on public.team_members for insert to authenticated with check ((select public.is_owner()));
drop policy if exists "owners update team members" on public.team_members;
create policy "owners update team members" on public.team_members for update to authenticated using ((select public.is_owner())) with check ((select public.is_owner()));

drop policy if exists "active members read parts" on public.parts;
create policy "active members read parts" on public.parts for select to authenticated using ((select public.is_active_member()));
drop policy if exists "active members insert parts" on public.parts;
create policy "active members insert parts" on public.parts for insert to authenticated with check ((select public.is_active_member()));
drop policy if exists "active members update parts" on public.parts;
create policy "active members update parts" on public.parts for update to authenticated using ((select public.is_active_member())) with check ((select public.is_active_member()));
drop policy if exists "active members delete parts" on public.parts;
create policy "active members delete parts" on public.parts for delete to authenticated using ((select public.is_active_member()));

drop policy if exists "active members read sales" on public.sales;
create policy "active members read sales" on public.sales for select to authenticated using ((select public.is_active_member()));
revoke all on public.sales from anon, authenticated;
grant select on public.sales to authenticated;
grant select, insert, update, delete on public.parts to authenticated;
grant select, insert, update on public.team_members to authenticated;

create or replace function public.record_sale(p_part_id uuid, p_quantity integer, p_unit_price numeric)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare v_part public.parts%rowtype; v_sale_id uuid;
begin
  if not public.is_active_member() then raise exception 'ანგარიშს წვდომა არ აქვს'; end if;
  if p_quantity is null or p_quantity < 1 then raise exception 'რაოდენობა უნდა იყოს დადებითი მთელი რიცხვი'; end if;
  if p_unit_price is null or p_unit_price < 0 then raise exception 'ფასი არასწორია'; end if;
  select * into v_part from public.parts where id = p_part_id for update;
  if not found then raise exception 'ნაწილი ვერ მოიძებნა'; end if;
  if v_part.quantity < p_quantity then raise exception 'მარაგში საკმარისი რაოდენობა არ არის'; end if;
  update public.parts set quantity = quantity - p_quantity, updated_at = now() where id = p_part_id;
  insert into public.sales(part_id,part_name,quantity,unit_price,unit_cost,sold_by,sold_by_email)
  values(v_part.id,v_part.name,p_quantity,p_unit_price,v_part.cost_price,(select auth.uid()),(select email from auth.users where id = (select auth.uid())))
  returning id into v_sale_id;
  return v_sale_id;
end; $$;
revoke all on function public.record_sale(uuid, integer, numeric) from public, anon;
grant execute on function public.record_sale(uuid, integer, numeric) to authenticated;

-- 1) შექმენით თქვენი ანგარიში აპში ან Supabase Authentication -> Users-ში.
-- 2) დააკოპირეთ თქვენი Auth User ID (UUID) და ქვემოთ YOUR_AUTH_USER_UUID ჩაანაცვლეთ.
-- 3) გაუშვით ეს ცალკე INSERT მფლობელის ანგარიშის შესაქმნელად:
-- insert into public.team_members(user_id,email,role,active)
-- values ('YOUR_AUTH_USER_UUID'::uuid,'your-email@example.com','owner',true);
