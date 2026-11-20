-- BOOKSPACE: jalankan di Supabase > SQL Editor
create table profiles(id uuid primary key references auth.users on delete cascade,full_name text,phone text,role text not null default 'customer' check(role in('customer','admin')),created_at timestamptz default now());
create table categories(id serial primary key,name text unique not null);
create table products(id uuid primary key default gen_random_uuid(),title text not null,author text,publisher text,category_id int references categories,price int not null check(price>=0),discount_pct int not null default 0 check(discount_pct between 0 and 90),description text,cover_url text,stock int not null default 0 check(stock>=0),isbn text,sold int not null default 0,rating_avg numeric(2,1) not null default 0,review_count int not null default 0,created_at timestamptz default now());
create table carts(id uuid primary key default gen_random_uuid(),user_id uuid unique not null references profiles on delete cascade,updated_at timestamptz default now());
create table cart_items(id uuid primary key default gen_random_uuid(),cart_id uuid not null references carts on delete cascade,product_id uuid not null references products,qty int not null check(qty>0),unique(cart_id,product_id));
create table addresses(id uuid primary key default gen_random_uuid(),user_id uuid not null references profiles on delete cascade,recipient text not null,phone text not null,street text not null,province text not null,city text not null,district text not null,postal_code text not null check(postal_code~'^\d{5}$'));
create table orders(id uuid primary key default gen_random_uuid(),order_no text unique not null,user_id uuid not null references profiles,address jsonb not null,subtotal int not null,discount int not null,shipping_cost int not null,total int not null,courier text,tracking_no text,shipping_status text not null default 'belum_dikirim' check(shipping_status in('belum_dikirim','dikemas','dikirim','selesai','dibatalkan')),created_at timestamptz default now());
create table order_items(id uuid primary key default gen_random_uuid(),order_id uuid not null references orders on delete cascade,product_id uuid not null references products,title text not null,unit_price int not null,qty int not null check(qty>0));
create table payments(id uuid primary key default gen_random_uuid(),order_id uuid unique not null references orders on delete cascade,gross_amount int not null,status text not null default 'pending' check(status in('pending','paid','failed','expired')),method text,midtrans_txn_id text,updated_at timestamptz default now());
create table reviews(id uuid primary key default gen_random_uuid(),product_id uuid not null references products,user_id uuid not null references profiles,rating int not null check(rating between 1 and 5),body text,created_at timestamptz default now(),unique(product_id,user_id));

create function is_admin() returns boolean language sql security definer stable as $$ select exists(select 1 from profiles where id=auth.uid() and role='admin') $$;
create function handle_new_user() returns trigger language plpgsql security definer as $$ begin insert into profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',new.raw_user_meta_data->>'name')); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();
create function decrement_stock(p_id uuid,q int) returns void language sql security definer as $$ update products set stock=greatest(stock-q,0),sold=sold+q where id=p_id $$;
revoke execute on function decrement_stock from public,anon,authenticated;

do $$ declare t text; begin foreach t in array array['profiles','categories','products','carts','cart_items','addresses','orders','order_items','payments','reviews'] loop execute format('alter table %I enable row level security',t); end loop; end $$;
create policy "katalog publik" on products for select using(true);
create policy "kategori publik" on categories for select using(true);
create policy "ulasan publik" on reviews for select using(true);
create policy "admin kelola produk" on products for all using(is_admin()) with check(is_admin());
create policy "admin kelola kategori" on categories for all using(is_admin()) with check(is_admin());
create policy "profil sendiri" on profiles for select using(id=auth.uid() or is_admin());
-- role TIDAK boleh diubah user: update hanya kolom aman lewat grant
create policy "edit profil sendiri" on profiles for update using(id=auth.uid()) with check(id=auth.uid());
revoke update on profiles from authenticated; grant update(full_name,phone) on profiles to authenticated;
create policy "cart sendiri" on carts for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "item cart sendiri" on cart_items for all using(exists(select 1 from carts c where c.id=cart_id and c.user_id=auth.uid())) with check(exists(select 1 from carts c where c.id=cart_id and c.user_id=auth.uid()));
create policy "alamat sendiri" on addresses for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "pesanan sendiri" on orders for select using(user_id=auth.uid() or is_admin());
create policy "admin update pesanan" on orders for update using(is_admin());
create policy "item pesanan sendiri" on order_items for select using(exists(select 1 from orders o where o.id=order_id and (o.user_id=auth.uid() or is_admin())));
create policy "pembayaran sendiri" on payments for select using(exists(select 1 from orders o where o.id=order_id and (o.user_id=auth.uid() or is_admin())));
create policy "ulasan sendiri" on reviews for insert with check(user_id=auth.uid());
-- Tidak ada policy INSERT/UPDATE untuk orders, order_items, payments: hanya server (service role) yang menulis.
-- Jadikan admin pertama (jalankan manual setelah daftar): update profiles set role='admin' where id='<UUID_ANDA>';
