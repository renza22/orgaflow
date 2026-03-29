# Orgaflow Supabase Migration Pack

Ini paket migrasi untuk **mengganti desain database lama ke desain baru** yang lebih cocok dengan:
- frontend/UI yang sekarang,
- ERD yang kamu kirim,
- pola penggunaan Supabase Auth + public schema.

## Rekomendasi cara pakai

### Opsi paling aman
Buat **project Supabase baru**, lalu jalankan file berikut berurutan:

1. `001_extensions_enums.sql`
2. `002_base_functions_and_auth.sql`
3. `003_master_tables.sql`
4. `004_core_tables.sql`
5. `005_analytics_views.sql`
6. `006_rpc_and_helpers.sql`
7. `007_rls_grants.sql`
8. `008_seed_master_data.sql`

### Opsi ganti project yang sekarang
Kalau kamu tetap mau pakai project Supabase lama:

1. backup dulu database lama
2. jalankan `000_optional_drop_existing_orgaflow.sql`
3. jalankan `001` sampai `008` sesuai urutan di atas

## Kenapa aku tambahkan RPC
Frontend flow baru untuk:
- create organization
- join organization dengan invite code

lebih aman kalau **tidak** dilakukan lewat insert langsung dari client.
Karena itu aku tambahkan 2 function:
- `create_organization_with_owner(...)`
- `join_organization_by_invite_code(...)`

Ini membuat flow lebih konsisten dan aman di Supabase.

## Hal penting yang sudah diperbaiki dari versi schema sebelumnya
- `v_member_workload` memakai `security_invoker = true`
- policy `profiles` diperluas supaya anggota satu organisasi bisa membaca profil dasar sesama anggota
- create/join organization dibuat lewat RPC, bukan direct insert mentah
- ditambahkan grants dan RLS untuk tabel yang sebelumnya belum lengkap
- workload view memakai `allocation_hours` bila ada, fallback ke `tasks.estimated_hours`

## Setelah migrasi selesai
Cek 5 hal ini:

1. sign up membuat row di `public.profiles`
2. create organization via RPC membuat:
   - row di `organizations`
   - row owner di `members`
3. join organization via invite code membuat / mengaktifkan row `members`
4. read dropdown master berhasil
5. user hanya bisa melihat data organisasi tempat dia menjadi member

## Catatan implementasi Flutter
Nanti di frontend baru, flow yang disarankan:
- register -> `supabase.auth.signUp`
- onboarding profile -> update `profiles`
- create org -> `rpc('create_organization_with_owner', ...)`
- join org -> `rpc('join_organization_by_invite_code', ...)`
- skill setup -> insert/update `member_skills`
- create project/task -> insert normal ke tabel inti
