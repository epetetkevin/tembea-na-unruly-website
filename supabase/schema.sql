-- TEMBEA NA UNRULY initial database schema for Supabase PostgreSQL.
create extension if not exists pgcrypto;

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(), title text not null, slug text not null unique,
  description text not null default '', destination text, event_date timestamptz not null,
  meeting_point text, itinerary text, cover_image_url text, published boolean not null default false,
  booking_deadline timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.ticket_categories (
  id uuid primary key default gen_random_uuid(), event_id uuid not null references public.events(id) on delete cascade,
  name text not null check (name in ('Regular','VIP','VVIP') or length(name) between 1 and 50),
  price numeric(12,2) not null check (price >= 0), capacity integer not null check (capacity >= 0),
  sold_quantity integer not null default 0 check (sold_quantity >= 0 and sold_quantity <= capacity),
  active boolean not null default true, early_bird_price numeric(12,2), early_bird_deadline timestamptz,
  available_quantity integer generated always as (capacity - sold_quantity) stored,
  created_at timestamptz not null default now(), unique(event_id,name)
);
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(), booking_reference text not null unique,
  event_id uuid not null references public.events(id), ticket_category_id uuid not null references public.ticket_categories(id),
  full_name text not null, phone text not null, email text not null,
  quantity integer not null check(quantity between 1 and 10), unit_price numeric(12,2) not null,
  total_amount numeric(12,2) not null check(total_amount >= 0),
  booking_status text not null default 'awaiting_payment' check(booking_status in ('awaiting_payment','confirmed','cancelled','refunded')),
  created_at timestamptz not null default now()
);
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id) on delete cascade,
  amount numeric(12,2) not null check(amount >= 0), payment_phone text not null,
  mpesa_code text, status text not null default 'pending' check(status in ('pending','verified','rejected','refunded')),
  submitted_at timestamptz not null default now(), verified_at timestamptz, verified_by uuid references auth.users(id),
  admin_note text, unique(mpesa_code)
);
create table if not exists public.media (
  id uuid primary key default gen_random_uuid(), title text not null, caption text, media_type text not null check(media_type in ('image','video','poster')),
  storage_path text not null, public_url text, category text, published boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(), booking_id uuid references public.bookings(id) on delete set null,
  recipient text not null, channel text not null check(channel in ('email','sms','whatsapp')),
  subject text, body text not null, status text not null default 'queued', sent_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.audit_logs (
  id bigint generated always as identity primary key, admin_user_id uuid references auth.users(id),
  action text not null, entity_type text not null, entity_id text, details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.admins where user_id = auth.uid());
$$;

create or replace function public.create_public_booking(
 p_event_id uuid, p_ticket_category_id uuid, p_quantity integer,
 p_full_name text, p_phone text, p_email text
) returns jsonb language plpgsql security definer set search_path=public as $$
declare t public.ticket_categories%rowtype; e public.events%rowtype; b public.bookings%rowtype; price_value numeric(12,2); ref_value text;
begin
 if p_quantity < 1 or p_quantity > 10 then raise exception 'INVALID_QUANTITY'; end if;
 if length(trim(p_full_name)) < 2 or length(p_full_name) > 120 then raise exception 'INVALID_NAME'; end if;
 select * into e from public.events where id=p_event_id and published=true and event_date > now() for share;
 if not found then raise exception 'EVENT_UNAVAILABLE'; end if;
 if e.booking_deadline is not null and now() > e.booking_deadline then raise exception 'BOOKING_CLOSED'; end if;
 select * into t from public.ticket_categories where id=p_ticket_category_id and event_id=p_event_id and active=true for update;
 if not found or t.available_quantity < p_quantity then raise exception 'SOLD_OUT'; end if;
 price_value := case when t.early_bird_price is not null and t.early_bird_deadline is not null and now() <= t.early_bird_deadline then t.early_bird_price else t.price end;
 update public.ticket_categories set sold_quantity=sold_quantity+p_quantity where id=t.id;
 ref_value := 'TNU-' || upper(substr(encode(gen_random_bytes(8),'hex'),1,10));
 insert into public.bookings(booking_reference,event_id,ticket_category_id,full_name,phone,email,quantity,unit_price,total_amount)
 values(ref_value,p_event_id,p_ticket_category_id,trim(p_full_name),trim(p_phone),lower(trim(p_email)),p_quantity,price_value,price_value*p_quantity) returning * into b;
 insert into public.payments(booking_id,amount,payment_phone,status) values(b.id,b.total_amount,trim(p_phone),'pending');
 return jsonb_build_object('id',b.id,'booking_reference',b.booking_reference,'total_amount',b.total_amount,'booking_status',b.booking_status);
end; $$;
revoke all on function public.create_public_booking(uuid,uuid,integer,text,text,text) from public;
grant execute on function public.create_public_booking(uuid,uuid,integer,text,text,text) to anon, authenticated;

alter table public.admins enable row level security;
alter table public.events enable row level security;
alter table public.ticket_categories enable row level security;
alter table public.bookings enable row level security;
alter table public.payments enable row level security;
alter table public.media enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

create policy "published events are public" on public.events for select to anon, authenticated using (published=true or public.is_admin());
create policy "admins manage events" on public.events for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "active tickets for published events are public" on public.ticket_categories for select to anon, authenticated using(active=true and exists(select 1 from public.events e where e.id=event_id and e.published=true) or public.is_admin());
create policy "admins manage tickets" on public.ticket_categories for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "admins read bookings" on public.bookings for select to authenticated using(public.is_admin());
create policy "admins manage bookings" on public.bookings for update to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "admins read payments" on public.payments for select to authenticated using(public.is_admin());
create policy "admins manage payments" on public.payments for update to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "public published media" on public.media for select to anon,authenticated using(published=true or public.is_admin());
create policy "admins manage media" on public.media for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "admins manage admins" on public.admins for select to authenticated using(user_id=auth.uid() or public.is_admin());
create policy "admins view notifications" on public.notifications for select to authenticated using(public.is_admin());
create policy "admins manage notifications" on public.notifications for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "admins view audit logs" on public.audit_logs for select to authenticated using(public.is_admin());
create policy "admins insert audit logs" on public.audit_logs for insert to authenticated with check(public.is_admin());

-- Create the first auth user through Supabase Dashboard first, then insert their UUID:
-- insert into public.admins(user_id) values ('PASTE_AUTH_USER_UUID_HERE');
-- Storage: create a bucket named `event-media`; make it public only if public URLs are intended.
-- Add storage.objects policies allowing authenticated admins (public.is_admin()) to upload/update/delete.
