# BOOKSPACE web (Next.js + Supabase + Midtrans), Tahap 1

## Struktur folder (target akhir; ✔ = sudah ada di Tahap 1)
bookspace-web/
├─ .env.example                      ✔
├─ supabase/
│  ├─ schema.sql                     ✔ tabel + RLS (versi lengkap, tambah kolom rating)
│  └─ seed.sql                       ✔ 10 kategori + 100 buku contoh
└─ src/
   ├─ proxy.ts                       ✔ (Next 16; di Next 15 jadi middleware.ts)
   ├─ types/db.ts                    ✔
   ├─ lib/supabase/
   │  ├─ client.ts  server.ts  admin.ts  proxy.ts   ✔
   ├─ app/
   │  ├─ layout.tsx  globals.css  page.tsx  ✔
   │  ├─ status/page.tsx             ✔ uji koneksi (hapus sebelum rilis)
   │  ├─ auth/callback/route.ts      ✔ tujuan Google OAuth + verifikasi email
   │  ├─ login, register, lupa-password, reset-password   (Tahap 2)
   │  ├─ katalog, buku/[id], keranjang                    (Tahap 3-4)
   │  ├─ checkout, pesanan, akun                          (Tahap 4-5)
   │  └─ api/midtrans/create, webhook                     (Tahap 4, dari paket backend)
   └─ components/                    (Tahap 2-3)

## Langkah pasang
1. Buat proyek:
   npx create-next-app@latest bookspace-web --ts --tailwind --eslint --app --src-dir --import-alias "@/*"
   cd bookspace-web
   npm i @supabase/supabase-js @supabase/ssr server-only
2. Salin semua file zip ini ke proyek, TIMPA file yang sama (layout.tsx, page.tsx, globals.css). Folder supabase/ ada di root proyek.
3. supabase.com > buat project > SQL Editor > jalankan `supabase/schema.sql`, lalu `supabase/seed.sql` (sekali saja).
4. Project Settings > API: salin URL dan Publishable key. Salin `.env.example` menjadi `.env.local`, isi nilainya. Kunci rahasia (service role, Midtrans server key) hanya di .env.local dan Vercel, tidak pernah di kode browser.
5. Authentication > URL Configuration: Site URL `http://localhost:3000`; Redirect URLs tambah `http://localhost:3000/auth/callback` (dan domain Vercel nanti).
6. `npm run dev`, buka http://localhost:3000/status.

## Cara uji Tahap 1
/status harus menampilkan: 3 variabel terisi, products = 100 baris, categories = 10 baris, sesi = belum login. Jika ada "GAGAL", salin pesannya ke saya.

Catatan: kode ini belum saya jalankan; hanya disusun mengikuti dokumentasi Supabase SSR terbaru. Seed adalah data fiktif untuk demo.
