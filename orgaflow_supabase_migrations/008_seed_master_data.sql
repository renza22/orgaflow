insert into public.organization_types (code, label, sort_order) values
  ('himpunan_mahasiswa', 'Himpunan Mahasiswa', 1),
  ('ukm', 'Unit Kegiatan Mahasiswa', 2),
  ('bem', 'Badan Eksekutif Mahasiswa', 3),
  ('senat_mahasiswa', 'Senat Mahasiswa', 4),
  ('komunitas', 'Komunitas', 5),
  ('lainnya', 'Lainnya', 6)
on conflict (code) do update set label = excluded.label, sort_order = excluded.sort_order;

insert into public.study_programs (code, label, sort_order) values
  ('teknik_informatika', 'Teknik Informatika', 1),
  ('sistem_informasi', 'Sistem Informasi', 2),
  ('manajemen', 'Manajemen', 3),
  ('akuntansi', 'Akuntansi', 4),
  ('ekonomi_pembangunan', 'Ekonomi Pembangunan', 5),
  ('ilmu_komunikasi', 'Ilmu Komunikasi', 6),
  ('desain_komunikasi_visual', 'Desain Komunikasi Visual', 7),
  ('psikologi', 'Psikologi', 8),
  ('hukum', 'Hukum', 9),
  ('sastra_inggris', 'Sastra Inggris', 10)
on conflict (code) do update set label = excluded.label, sort_order = excluded.sort_order;

insert into public.position_templates (code, label, sort_order) values
  ('ketua_umum', 'Ketua Umum', 1),
  ('wakil_ketua', 'Wakil Ketua', 2),
  ('sekretaris', 'Sekretaris', 3),
  ('bendahara', 'Bendahara', 4),
  ('koordinator_divisi', 'Koordinator Divisi', 5),
  ('staf_medkominfo', 'Staf Medkominfo', 6),
  ('staf_humas', 'Staf Humas', 7),
  ('staf_event', 'Staf Event', 8),
  ('anggota_biasa', 'Anggota Biasa', 9)
on conflict (code) do update set label = excluded.label, sort_order = excluded.sort_order;

insert into public.division_templates (code, label, sort_order) values
  ('media_komunikasi', 'Media & Komunikasi', 1),
  ('acara_event', 'Acara & Event', 2),
  ('keuangan_administrasi', 'Keuangan & Administrasi', 3),
  ('hubungan_masyarakat', 'Hubungan Masyarakat', 4),
  ('pengembangan_sdm', 'Pengembangan SDM', 5),
  ('riset_inovasi', 'Riset & Inovasi', 6),
  ('teknologi_informasi', 'Teknologi Informasi', 7)
on conflict (code) do update set label = excluded.label, sort_order = excluded.sort_order;

insert into public.portfolio_platforms (code, label, sort_order) values
  ('linkedin', 'LinkedIn', 1),
  ('github', 'GitHub', 2),
  ('behance', 'Behance', 3),
  ('portfolio_website', 'Portfolio Website', 4),
  ('instagram', 'Instagram', 5),
  ('dribbble', 'Dribbble', 6)
on conflict (code) do update set label = excluded.label, sort_order = excluded.sort_order;

insert into public.skill_categories (code, label, sort_order) values
  ('creative', 'Creative', 1),
  ('administrative', 'Administrative', 2),
  ('technical', 'Technical', 3),
  ('communication', 'Communication', 4)
on conflict (code) do update set label = excluded.label, sort_order = excluded.sort_order;

insert into public.skills (category_code, name, sort_order) values
  ('creative', 'Graphic Design', 1),
  ('creative', 'Video Editing', 2),
  ('creative', 'Photography', 3),
  ('creative', 'Content Writing', 4),
  ('creative', 'Copywriting', 5),
  ('creative', 'UI/UX Design', 6),
  ('creative', 'Illustration', 7),
  ('creative', 'Motion Graphics', 8),
  ('administrative', 'Project Management', 1),
  ('administrative', 'Data Entry', 2),
  ('administrative', 'Documentation', 3),
  ('administrative', 'Event Planning', 4),
  ('administrative', 'Budgeting', 5),
  ('administrative', 'Report Writing', 6),
  ('technical', 'Web Development', 1),
  ('technical', 'Mobile Development', 2),
  ('technical', 'Data Analysis', 3),
  ('technical', 'Social Media Management', 4),
  ('technical', 'SEO/SEM', 5),
  ('technical', 'Database Management', 6),
  ('communication', 'Public Speaking', 1),
  ('communication', 'Presentation', 2),
  ('communication', 'Social Media Strategy', 3),
  ('communication', 'PR & Relations', 4),
  ('communication', 'Marketing', 5),
  ('communication', 'Networking', 6)
on conflict (name) do nothing;
