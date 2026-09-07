# Aturan Final DipoFeed

Dokumen ini merangkum kontrak data, impor/ekspor, angka, perhitungan, status, dan alur layar yang harus konsisten dengan implementasi.

## Data master pakan

- `assets/data/bahan_pakan.csv` adalah seed kanonik (32 record) dan sumber runtime untuk seed awal serta reset data.
- `assets/data/bahan_pakan.json` hanya backup; tidak dibaca pada jalur runtime.
- CSV memakai format **comma-delimited**, desimal **titik (`.`)** , dan **CSV quoting** standar untuk field yang mengandung koma, quote, atau newline.
- Header persis (16 kolom):

  ```text
  No,Bahan Pakan,Kategori,Harga/kg,BK (%),Abu (%),Lemak (%),Serat (%),Protein (%),BETN (%),TDN (%),ME (KJoule/kg),Ca (%),P (%),Sumber
  ```

- Kolom `No` dan `Sumber` hanya untuk ekspor; saat impor kolom tak dikenal (termasuk `No`, `Sumber`, atau kolom tambahan lain) **dilewati** selama semua kolom wajib (`Bahan Pakan`, `Kategori`, `Harga/kg`, `BK (%)`–`P (%)`) ada.
- Harga dalam CSV tanpa prefix `Rp`; saat impor prefix `Rp` otomatis diabaikan.
- Field nutrisi diekspor dengan 2 angka desimal. `harga` diekspor dengan 0 angka desimal.
- **Hanya 2 kategori** yang valid: `hijauan` dan `konsentrat`. Kategori legacy `lainnya`, `energi`, dan `limbah` saat ekspor otomatis dikonversi menjadi `konsentrat`, dan saat impor ditolak (harus diedit menjadi `hijauan`/`konsentrat`).
- Seed memberi ID deterministik berdasarkan `row index + 1` dan mengaktifkan semua baris. Mengubah urutan baris seed mengubah ID; migrasi seed harus memperlakukan perubahan urutan sebagai risiko identitas data.
- Dalam klasifikasi formulasi, hanya `hijauan` yang dihitung sebagai hijauan; semua kategori lain (`konsentrat`) dihitung sebagai konsentrat.

## Format tampilan angka (display)

- Angka yang ditampilkan di UI menggunakan format **Indonesia**: koma (`,`) sebagai desimal, titik (`.`) sebagai pemisah ribuan.
- Contoh: `29,24` (BK), `Rp4.500` (harga), `1.234,50` (PK).
- Format ini hanya untuk layar; format CSV berbeda (lihat di atas).

## Impor dan ekspor CSV

- Nama dan kategori input dipangkas; pencocokan nama untuk impor tidak membedakan kapitalisasi.
- Nama duplikat setelah trim dan normalisasi memakai baris terakhir. Baris yang diproses adalah baris unik setelah normalisasi (duplikat di CSV hanya dihitung 1 baris).
- Nama yang cocok dengan data tersimpan mempertahankan ID lama. Nama baru mendapat ID baru setelah ID maksimum yang ada.
- Semua baris hasil impor menjadi aktif.
- Data lama yang tidak ada di CSV dihapus permanen. Ringkasan impor melaporkan jumlah ditambah, diperbarui, dihapus, dan baris diproses.
- Validasi penuh dilakukan sebelum dialog konfirmasi. CSV tidak valid tidak boleh mengubah data.
- Penggantian memakai commit atomik. Jika penulisan gagal, repository dan persistence di-rollback ke snapshot sebelumnya.
- Ekspor memakai header, urutan kolom, pemisah, normalisasi kategori, dan presisi yang sama dengan format kanonik.
- Nilai numerik CSV harus finite dan tidak negatif.

## Angka dan validasi

- Parser display (Indonesia) menerima format desimal koma, pemisah ribuan titik, dan bilangan bulat.
- `parse` melempar `FormatException` untuk input kosong, malformed, non-finite, atau finite dengan magnitudo `abs >= 1e21`. `tryParse` mengembalikan `null` pada kondisi yang sama.
- Formatter display menghasilkan pemisah Indonesia sesuai jumlah desimal yang diminta dan menolak nilai non-finite atau `abs >= 1e21`.
- Nama bahan yang diawali `=`, `+`, `-`, atau `@` ditolak saat parse maupun ekspor.
- Sebelum Cek Kecukupan Pakan atau Rekomendasi Pakan menghitung, seluruh record `BahanPakan` tersimpan diperiksa untuk `BK`, `abu`, `lemak`, `serat`, `PK`, `BETN`, `TDN`, `ME`, `harga`, `Ca`, dan `P`: semuanya harus finite dan tidak negatif. Bahan yang benar-benar dipakai juga wajib memiliki `BK > 0`.
- Target kebutuhan dan semua keluaran kalkulasi harus finite dan tidak negatif.

## Rumus kebutuhan nutrien

Implementasi memakai tabel dan worksheet yang dirujuk dari **National Research Council (NRC), *Nutrient Requirements of Dairy Cattle*, edisi revisi ke-5 (1978)** untuk Dara dan **edisi revisi ke-6 (1988)** untuk Laktasi. Nilai di antara titik tabel dihitung dengan interpolasi linear; di luar rentang tabel dicatat sebagai ekstrapolasi.

### Dara, NRC 1978

BK, TDN, PK, Ca, dan P diambil dari tabel kebutuhan berdasarkan BB. PK tabel dalam gram dikonversi menjadi kg:

`PK kg = PK gram / 1.000`

### Laktasi, NRC 1988

- `FCM4 = (0,4 * produksi susu) + (15 * (lemak susu / 100) * produksi susu)`
- `BK kg = (BK %BB / 100) * BB`
- `TDN total = TDN hidup pokok + TDN produksi FCM`
- `PK total = (PK hidup pokok + PK produksi FCM) / 1.000`
- `Ca total = Ca hidup pokok + Ca produksi FCM`
- `P total = P hidup pokok + P produksi FCM`

Persentase BK, kebutuhan hidup pokok, dan kontribusi produksi diinterpolasi dari tabel implementasi. Lemak susu di luar rentang tabel tetap dihitung dengan ekstrapolasi dan diberi catatan.

### Kering Kandang

`BK kg = 0,02 * BB`

TDN, PK, Ca, dan P diambil melalui interpolasi tabel BB. PK gram dikonversi menjadi kg.

## Rumus kontribusi pakan

Kandungan bahan dibaca sebagai persentase basis bahan kering (BK), sedangkan jumlah input peternak adalah as-fed:

- `BK aktual = jumlah as-fed (kg) * BK (%) / 100`
- `PK aktual = BK aktual * PK (%) / 100`
- `TDN aktual = BK aktual * TDN (%) / 100`
- `ME aktual = ME bahan * BK aktual (kg)`
- `LK aktual = BK aktual * lemak (%) / 100`
- `SK aktual = BK aktual * serat (%) / 100`
- `BETN aktual = BK aktual * BETN (%) / 100`
- `Ca aktual (gram) = BK aktual * Ca (%) / 100 * 1.000`
- `P aktual (gram) = BK aktual * P (%) / 100 * 1.000`

Pada Cek Kecukupan Pakan, BK, PK, dan TDN pemberian dihitung dari total berat as-fed dikalikan persentase campuran tertimbang. Pemberian Ca dan P pada ringkasan fitur masih `0` karena jalur ringkasnya belum memakai data Ca/P bahan.

Pada Rekomendasi Pakan, target BK dibagi `60%` untuk hijauan dan `40%` untuk konsentrat. Hanya kategori `hijauan` yang masuk kelompok hijauan.

Pada Cek Kandungan Pakan:

- `total berat = Σ jumlah bahan`
- `total biaya = Σ (jumlah bahan * harga per kg)`
- `nutrien campuran = Σ ((jumlah bahan / total berat) * nutrien bahan)`

## Status perhitungan

Status bersama:

- `Belum dihitung`: belum ada snapshot hasil yang valid atau input berubah setelah hasil terakhir.
- `Perhitungan berhasil`: input valid, output finite dan tidak negatif, dan hasil dapat ditampilkan.
- `Gagal menghitung`: input tersimpan, input pengguna, target, atau output tidak valid; hasil tidak boleh dipertahankan.

### Cek Kecukupan Pakan

Tiga tahap:

1. `Data Sapi`
2. `Kebutuhan Nutrien dan Pemberian Pakan`
3. `Hasil Evaluasi Nutrisi`

Tahap berikutnya hanya terbuka setelah validasi tahap aktif berhasil. `Kembali` mempertahankan input. Mengedit profil sapi atau pemberian pakan menginvalidasi hasil; tahap hasil harus dihitung ulang sebelum dianggap valid.

Status nutrien memakai:

`selisih = total pemberian - total kebutuhan`

Dengan ambang `±0,0001`:

- `Kurang` jika selisih `< -0,0001`
- `Cukup` jika `-0,0001 ≤ selisih ≤ 0,0001`
- `Berlebih` jika selisih `> 0,0001`

### Rekomendasi Pakan

Tiga tahap:

1. `Data Sapi`
2. `Bahan Pakan Tersedia`
3. `Hasil Rekomendasi`

Tahap berikutnya hanya terbuka setelah validasi tahap aktif berhasil, termasuk minimal satu hijauan dan satu konsentrat pada tahap bahan. `Kembali` mempertahankan input. Mengedit profil atau pilihan bahan menghapus rekomendasi dan mengembalikan status ke `Belum dihitung`; hasil harus dihitung ulang.

Status nutrien memakai toleransi relatif `±5%` terhadap target. LK aman jika `LK ≤ 5% BK`.

### Cek Kandungan Pakan

Tetap satu halaman, tanpa stepper. Perhitungan hanya dilakukan saat pengguna menekan `Hitung` setelah input valid dan total campuran lebih dari `0 kg`.

Hasil berhasil adalah snapshot dari input terakhir saat tombol `Hitung` ditekan. Mengubah bahan, jumlah, harga, atau fisiologi menghapus hasil dan mengembalikan status ke `Belum dihitung`. Perubahan tidak boleh mengubah snapshot lama secara diam-diam.

Standar evaluasi campuran:

- BK maksimum `86%`.
- LK maksimum `7%`.
- Protein target dengan toleransi `±1` poin persentase.
- TDN sesuai dari minimum sampai `minimum + 4` poin persentase.
- Ca dan P sesuai jika berada di dalam rentang fisiologi.