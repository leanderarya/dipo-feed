# DipoFeed

DipoFeed adalah aplikasi mobile Flutter untuk membantu peternak sapi perah dan ahli nutrisi menghitung, memformulasi, dan mengevaluasi ransum berdasarkan profil sapi serta kandungan bahan pakan.

## Ringkasan penggunaan

- **Database Pakan:** impor CSV untuk mengganti seluruh database lokal setelah validasi penuh dan konfirmasi pengguna. Ekspor CSV memakai format kanonik yang dapat diimpor kembali: pemisah `;`, header tetap, angka Indonesia, nutrisi 2 desimal, dan harga 0 desimal.
- **Kategori:** hanya kategori persis `hijauan` yang diklasifikasikan sebagai hijauan. `konsentrat` dan `lainnya` diperlakukan sebagai konsentrat pada fitur rekomendasi.
- **Angka Indonesia:** titik adalah pemisah ribuan dan koma adalah pemisah desimal, misalnya `4.500` dan `1.234,50`. Angka finite dengan magnitudo `abs < 1e21` dapat diproses.
- **Status:** layar perhitungan memakai `Belum dihitung`, `Perhitungan berhasil`, dan `Gagal menghitung`. Hasil tidak ditampilkan sebagai berhasil jika input tersimpan atau keluaran kalkulasi tidak valid.
- **Stepper:** Cek Kecukupan Pakan dan Rekomendasi Pakan memiliki tiga tahap. Tahap berikutnya hanya terbuka setelah tahap aktif valid; kembali mempertahankan input dan perubahan input mengharuskan perhitungan ulang.
- **Cek Kandungan Pakan:** tetap satu halaman tanpa stepper. Pengguna menyusun campuran lalu menekan `Hitung` secara manual. Hasil berhasil adalah snapshot input terakhir; perubahan bahan, jumlah, harga, atau fisiologi menghapus snapshot dan mengembalikan status ke `Belum dihitung`.

## Fitur utama

### Cek Kecukupan Pakan

Membandingkan kebutuhan nutrien sapi dengan nutrien dari pemberian pakan as-fed. Input terdiri dari fisiologi, berat badan, produksi susu dan lemak susu untuk laktasi, serta bahan pakan dan berat basahnya.

Stepper:

1. `Data Sapi`
2. `Kebutuhan Nutrien dan Pemberian Pakan`
3. `Hasil Evaluasi Nutrisi`

Hasil membandingkan BK, protein, TDN, Ca, dan P. Status per komponen adalah `Kurang`, `Cukup`, atau `Berlebih`.

### Rekomendasi Pakan

Menghasilkan takaran as-fed untuk mencapai target BK dengan proporsi 60% hijauan dan 40% konsentrat, lalu mengevaluasi protein, TDN, Ca, P, dan LK.

Stepper:

1. `Data Sapi`
2. `Bahan Pakan Tersedia`
3. `Hasil Rekomendasi`

Tahap bahan wajib memiliki sedikitnya satu hijauan dan satu bahan non-hijauan. Semua nilai nutrisi dan harga dari data tersimpan divalidasi sebelum pencarian kombinasi.

### Cek Kandungan Pakan

Memungkinkan pengguna mencampur beberapa bahan dengan jumlah dan harga per kg, menghitung komposisi campuran, biaya, dan evaluasi terhadap standar fisiologi.

### Database Pakan

Menyediakan katalog lokal bahan pakan untuk dilihat, ditambah, diubah, diaktifkan, dihapus, di-reset, diimpor, dan diekspor. Data ini menjadi sumber seluruh kalkulasi.

## Rumus dan referensi teknis

Seluruh persentase kandungan bahan dibaca sebagai nilai basis bahan kering (BK), kecuali komposisi campuran pada Cek Kandungan yang dihitung sebagai rata-rata tertimbang berdasarkan jumlah as-fed.

### Kebutuhan sapi

Implementasi memakai tabel dan worksheet yang dirujuk dari **National Research Council (NRC), *Nutrient Requirements of Dairy Cattle*, edisi revisi ke-5 (1978)** untuk Dara dan **edisi revisi ke-6 (1988)** untuk Laktasi. Nilai di antara titik tabel dihitung dengan interpolasi linear; di luar rentang tabel dicatat sebagai ekstrapolasi.

- **Dara, NRC 1978:** kebutuhan BK, TDN, PK, Ca, dan P diambil dari tabel BB. PK tabel dalam gram dikonversi menjadi kg dengan `PK kg = PK gram / 1.000`.
- **Laktasi, NRC 1988:**
  - `FCM4 = (0,4 * produksi susu) + (15 * (lemak susu / 100) * produksi susu)`
  - `BK kg = (BK %BB / 100) * BB`
  - `TDN total = TDN hidup pokok + TDN produksi FCM`
  - `PK total = (PK hidup pokok + PK produksi FCM) / 1.000`
  - `Ca total = Ca hidup pokok + Ca produksi FCM`
  - `P total = P hidup pokok + P produksi FCM`
- **Kering Kandang:** `BK kg = 0,02 * BB`; TDN, PK, Ca, dan P diambil melalui interpolasi tabel BB. PK gram dikonversi menjadi kg.

### Kontribusi pakan

- `BK aktual = jumlah as-fed (kg) * BK (%) / 100`
- `PK aktual = BK aktual * PK (%) / 100`
- `TDN aktual = BK aktual * TDN (%) / 100`
- `LK aktual = BK aktual * lemak (%) / 100`
- `SK aktual = BK aktual * serat (%) / 100`
- `BETN aktual = BK aktual * BETN (%) / 100`
- `Ca aktual (gram) = BK aktual * Ca (%) / 100 * 1.000`
- `P aktual (gram) = BK aktual * P (%) / 100 * 1.000`

Pada Cek Kecukupan Pakan, BK, PK, dan TDN pemberian dihitung dari total berat as-fed dikalikan persentase campuran tertimbang. Pemberian Ca dan P pada ringkasan fitur tersebut masih `0` karena jalur ringkasnya belum memakai data Ca/P bahan.

Pada Rekomendasi Pakan, target BK dibagi `60%` untuk hijauan dan `40%` untuk konsentrat. Hanya kategori `hijauan` yang masuk kelompok hijauan.

Pada Cek Kandungan Pakan:

- `total berat = Σ jumlah bahan`
- `total biaya = Σ (jumlah bahan * harga per kg)`
- `nutrien campuran = Σ ((jumlah bahan / total berat) * nutrien bahan)`

### Status dan ambang

- Cek Kecukupan Pakan memakai `selisih = pemberian - kebutuhan` dengan toleransi `±0,0001`: di bawah batas `Kurang`, di atas batas `Berlebih`, dan di dalam batas `Cukup`.
- Rekomendasi Pakan memakai toleransi relatif `±5%` terhadap target untuk status nutrien. LK aman jika `LK ≤ 5% BK`.
- Cek Kandungan Pakan memakai standar fisiologi: BK maksimum `86%`, LK maksimum `7%`, protein target dengan toleransi `±1` poin persentase, TDN sesuai dari minimum sampai `minimum + 4` poin, serta Ca dan P sesuai di dalam rentang fisiologinya.
- Semua hasil kalkulasi harus finite dan tidak negatif sebelum status berhasil diberikan.
