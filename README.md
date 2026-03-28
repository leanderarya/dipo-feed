# DipoFeed

DipoFeed adalah aplikasi berbasis seluler (Mobile App) yang dibangun menggunakan Flutter. Aplikasi ini dirancang untuk membantu peternak sapi perah atau ahli nutrisi hewan dalam menghitung, memformulasi, dan mengevaluasi ransum (pakan) sapi secara tepat berdasarkan profil sapi dan kandungan nutrisi bahan pakan. Fokus utama aplikasi adalah pada evaluasi kandungan nutrisi seperti Bahan Kering (BK), Protein Kasar, Total Digestible Nutrients (TDN), dan Energi Metabolisme (ME).

---

## 🛠️ Sistem dan Teknologi

- **Sistem Operasi**: Cross-platform (Dapat dikompilasi ke Android / iOS / Web)
- **Framework Utama**: Flutter (Dart)
- **Arsitektur Data**: Menggunakan pendekatan manipulasi state lokal melalui berbagai layar simulasi. Logic perhitungan dipisah ke dalam modul independen seperti class `PerhitunganKecukupanPakan` dan `PerhitunganFormulasi`.

---

## 📱 Penjelasan Fitur dan Alur Kerja

Aplikasi DipoFeed memiliki 3 fitur utama. Berikut adalah penjelasan konsep, masukan (input), keluaran (output), beserta ilustrasi alur kerjanya:

### 1. Cek Kandungan Nutrisi
**Deskripsi:** Fitur referensi yang bertindak sebagai *database* ensiklopedia mini untuk melihat profil nutrisi dari berbagai bahan pakan lokal.
- **Konsep:** Pengguna dapat mencari dan melihat komposisi zat gizi dari suatu pakan (misalnya: Rumput Odot, Ampas Tahu, Bekatul, dll).
- **📝 Input:** Pencarian nama bahan pakan (opsional).
- **📤 Output:** Informasi profil nutrisi meliputi: Bahan Kering (BK), Protein, Total Digestible Nutrients (TDN), Energi Metabolisme (ME), Lemak, Abu, Serat, dll.

### 2. Cek Kecukupan Pakan
**Deskripsi:** Fitur ini berfungsi untuk mengevaluasi apakah *satu porsi pakan spesifik* yang biasa diberikan peternak sudah memenuhi standar kebutuhan gizi seekor sapi atau belum.

**Logika & Alur Kerja:**
Sistem memecah proses menjadi dua jalur: mengkalkulasi **"Apa yang dibutuhkan sapi"** dan **"Apa yang diberikan oleh pakan"**. Keduanya lalu diadu untuk mencari selisihnya (kurang/Cukup/Berlebih).

```mermaid
graph TD
    A[Input Profil Sapi] --> C{Sistem Hitung Kebutuhan Minimal}
    B[Input Jenis & Takaran Pakan] --> D{Sistem Hitung Sumbangan Nutrisi Pakan}
    C --> E[Bandingkan & Evaluasi]
    D --> E
    E --> F[Hasil: Status Kurang/Cukup/Berlebih]
```

- **📝 Input:**
  1. **Profil Sapi:** Berat Badan, Produksi Susu (liter), % Lemak Susu, Paritas, Tahap Laktasi, dan Status Kebuntingan.
  2. **Pakan Terpilih:** Milih satu kombinasi pakan beserta berat basahnya (kg).
- **📤 Output:**
  Tabel rincian evaluasi Nutrisi (BK, Protein, TDN, Energi ME). Jika asupan pakan lebih rendah dari kebutuhan sapi, statusnya merah (**Kurang**).

### 3. Formulasi Ransum
**Deskripsi:** Fitur simulasi tingkat lanjut (kalkulator utama). Memungkinkan peternak mensimulasikan "mencampur" berbagai macam bahan pakan dengan takaran berbeda-beda, lalu mengevaluasi apakah campuran seluruh pakan tersebut bagus untuk sapi.

**Logika & Alur Kerja:**
Sistem mengakumulasi seluruh pakan yang ada di "keranjang" campuran, menghitung total nutrisinya, dan membaginya sesuai kategori pakan (Hijauan vs Konsentrat) untuk mencari rasio seimbang.

```mermaid
graph TD
    A[Input Profil Sapi] --> C{Hitung Kebutuhan Sapi}
    
    B1[Bahan Pakan A - 5 kg] --> D{Akumulasi Total Nutrisi Campuran}
    B2[Bahan Pakan B - 2 kg] --> D
    B3[Bahan Pakan C - 1 kg] --> D
    
    C --> E[Evaluasi Kombinasi Pakan]
    D --> E
    D --> F[Hitung Rasio Hijauan vs Konsentrat]
    E --> G[Output Hasil Simulasi Ransum]
    F --> G
```

- **📝 Input:**
  1. **Profil Sapi** (Sama seperti fitur sebelumnya).
  2. **Keranjang Pakan:** *List* atau daftar berbagai macam bahan pakan beserta berat masing-masing (kg).
- **📤 Output:**
  1. **Total Nutrisi Keseluruhan:** Akumulasi BK, Protein, TDN, dan ME dari *seluruh* pakan.
  2. **Imbangan / Rasio:** Perbandingan persentase antara kategori Hijauan dan Konsentrat.
  3. **Kesimpulan:** Pesan rekomendasi apakah ransum ini sudah pas, berlebih, atau masih ada komposisi gizi yang kurang.

---

## 🧮 Detail Perhitungan (Referensi Teknis)
*Bagian ini memuat detail matematis di balik layar yang digunakan sistem untuk mengeksekusi fitur-fitur di atas. Seluruh perhitungan distandarisasi menggunakan basis **Bahan Kering (BK)**.*

### A. Rumus Kebutuhan Nutrisi Sapi
Untuk mengevaluasi pakan, sistem menghitung angka baku minimal yang dibutuhkan sapi berdasarkan kondisi fisiologisnya:

| Komponen Gizi | Rumus / Estimasi Sistem |
| :--- | :--- |
| **Kebutuhan BK** | `((2.0% s/d 4.0% berdasarkan Laktasi) / 100) * Berat Badan` |
| **Kebutuhan Protein** | `12% * Kebutuhan BK` |
| **Kebutuhan TDN** | `65% * Kebutuhan BK` |
| **Kebutuhan ME** | `(0.11 * B.Badan) + (Kandungan Susu * 7.5) + Tambahan Bunting` |

*(Catatan: Tambahan energi bunting diberikan bila usia kehamilan mencapai atau lebih dari 6 bulan: berturut-turut +6, +8, +15, dan +27 MCal per bulannya).*

### B. Rumus Konversi Sumbangan Pakan (As-Fed ke Nutrisi Aktual)
Karena takaran pakan dari petani biasanya basah (*as-fed*), sistem mengonversinya ke bobot murni (Bahan Kering) terlebih dahulu sebelum menghitung protein dan energinya:

| Komponen Terkalkulasi | Rumus Konversi |
| :--- | :--- |
| **Bahan Kering (BK) Aktual** | `(% BK Pakan / 100) * Takaran Pakan Segar (kg)` |
| **Sumbangan Protein** | `(% Protein Pakan / 100) * BK Aktual (kg)` |
| **Sumbangan TDN** | `(% TDN Pakan / 100) * BK Aktual (kg)` |
| **Sumbangan ME** | `Batas ME Pakan * BK Aktual (kg)` |

### C. Logika Evaluasi & Penentuan Status
Angka Asupan dari Pakan (Bagian B) dikurangi Angka Kebutuhan Sapi (Bagian A).
- **Rumus:** `Selisih = Total Asupan Pakan - Total Kebutuhan Sapi`
- Ambang Toleransi (Threshold): `+/- 0.0001`
- **Kurang**: Jika selisih bernilai negatif (Asupan < Kebutuhan).
- **Cukup**: Jika asupan tepat dan seimbang.
- **Berlebih**: Jika selisih bernilai positif (Asupan > Kebutuhan).

### D. Rasio Hijauan dan Konsentrat
Setiap pakan memiliki label kategori spesifik. Sistem mengklasifikasikan pakan bertipe *Hijauan* dan *Limbah* ke dalam satu wadah Hijauan, sisanya sebagai Konsentrat.
- **Rumus Persentase**: `(Total BK Kategori / Total Keseluruhan BK Semua Pakan) * 100%`
