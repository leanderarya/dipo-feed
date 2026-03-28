# DipoFeed

DipoFeed adalah aplikasi berbasis seluler (Mobile App) yang dibangun menggunakan Flutter. Aplikasi ini dirancang untuk membantu peternak sapi perah atau ahli nutrisi hewan dalam menghitung, memformulasi, dan mengevaluasi ransum (pakan) sapi secara tepat berdasarkan profil sapi dan kandungan nutrisi bahan pakan. Fokus utama aplikasi adalah pada evaluasi kandungan nutrisi seperti Bahan Kering (BK), Protein Kasar, Total Digestible Nutrients (TDN), dan Energi Metabolisme (ME).

## 📱 Fitur Utama

Aplikasi DipoFeed memiliki beberapa fitur inti:

1. **Cek Kandungan Nutrisi**: Melihat daftar bahan pakan lokal beserta profil nutrisinya (Bahan Kering/BK, Protein Kasar, TDN, ME, Lemak, Abu, dll).
2. **Cek Kecukupan Pakan**: Mengevaluasi apakah pemberian suatu takaran pakan konvensional sudah memenuhi standar kebutuhan sapi berdasarkan profilnya.
3. **Formulasi Ransum**: Simulasi atau kalkulator komprehensif untuk meracik beberapa jenis bahan pakan dan mengevaluasi hasilnya terhadap pemenuhan nutrisi sapi, serta menentukan rasio hijauan berbanding konsentrat.

## 🛠️ Sistem dan Teknologi

- **Sistem Operasi**: Cross-platform (Dapat dikompilasi ke Android / iOS / Web)
- **Framework Utama**: Flutter (Dart)
- **Arsitektur Data**: Menggunakan pendekatan manipulasi state lokal melalui berbagai layar simulasi (`FormulasiRansumScreen`). Logic perhitungan dipisah ke dalam modul independen seperti `PerhitunganKecukupanPakan` dan `PerhitunganFormulasi`.

## 📥 Input (Masukan)

Untuk menjalankan Formulasi Ransum atau Cek Kecukupan Pakan, sistem membutuhkan input dari pengguna berupa:

### 1. Profil Sapi
Data mengenai kondisi fisiologis sapi saat ini, meliputi:
- **Berat Badan (kg)**: Bobot atau berat hidup sapi.
- **Produksi Susu (liter/hari)**: Jumlah produksi susu yang dihasilkan secara harian.
- **Persentase Lemak Susu (%)**: Tingkat kandungan lemak dari susu.
- **Paritas**: Jumlah laktasi/persalinan sapi.
- **Tahap Laktasi**: Fase produksi susu, terdiri dari 5 fase: Kering Kandang, Awal Laktasi (Minggu 0-4), Awal Laktasi (Minggu 4-16), Tengah Laktasi (Minggu 16-30), dan Akhir Laktasi (Minggu 30-44).
- **Status Kebuntingan**: Apakah sapi sedang bunting atau tidak.
- **Bulan Bunting**: Jika bunting, kehamilan masuk bulan ke berapa (dihitung khusus mulai bulan ke-6 dan seterusnya).

### 2. Formulasi Pakan (Bahan Pakan)
Data bahan dan porsi pemberian harian, meliputi:
- Memilih satu atau beberapa jenis **Bahan Pakan** yang disediakan dari *database* (misalnya Rumput Odot, Ampas Tahu, Konsentrat, dll).
- Memasukkan takaran **Jumlah pakan (kg)** dalam kondisi segar (*as fed*).

## 🧮 Cara Kerja dan Perhitungan

Sistem bekerja dalam 3 tahapan utama: menghitung batas minimal/kebutuhan nutrisi sapi, menghitung total nutrisi dari pakan yang diramu, lalu membandingkannya (evaluasi). Seluruh perhitungan distandarisasi menggunakan basis **Bahan Kering (BK)** untuk akurasi konversi.

### Tahap 1: Menghitung Kebutuhan Nutrisi Sapi
1. **Kebutuhan BK (Bahan Kering)**: Diukur sebagai persentase dari berat badan (2.0% s/d 4.0%) bergantung pada *Tahap Laktasi*.
   - *Formula*: `(Persentase BK Tahap Laktasi / 100) * Berat Badan`
2. **Kebutuhan Energi (ME - Metabolizable Energy)**: Didapat dari akumulasi energi pokok, energi produksi susu, dan tambahan energi bila bunting tua.
   - *Formula Pokok*: `0.11 * Berat Badan`
   - *Formula Produksi*: `Produksi Susu * 7.5`
   - *Tambahan Kebuntingan*: (berlaku bila kehamilan >= 6 bulan) Bulan ke-6 (+6 ME), ke-7 (+8 ME), ke-8 (+15 ME), ke-9 dan sterusnya (+27 ME).
   - *Total ME* = `Energi Pokok + Produksi + Kebuntingan`
3. **Kebutuhan Protein Kasar**: Aplikasi menggunakan estimasi baku **12%** dari kebutuhan BK.
   - *Formula*: `Kebutuhan BK Kg * 0.12`
4. **Kebutuhan TDN (Total Digestible Nutrients)**: Aplikasi menggunakan estimasi baku **65%** dari kebutuhan BK.
   - *Formula*: `Kebutuhan BK Kg * 0.65`

### Tahap 2: Menghitung Sumbangan Nutrisi Pakan (Asupan)
Untuk setiap bahan pakan yang diinputkan pengguna, sistem mengonversinya dari bentuk segar (*as fed*) pelan-pelan ke bentuk bahan kering dan kandungan intinya:
- **BK Asupan (Kg)** = `(Kandungan BK Pakan / 100) * Jumlah Pakan Segar (Kg)`
- **Protein Kasar Asupan (Kg)** = `(Kandungan Protein Pakan / 100) * BK Asupan (Kg)`
- **TDN Asupan (Kg)** = `(Kandungan TDN Pakan / 100) * BK Asupan (Kg)`
- **ME Asupan (Mcal)** = `Kandungan ME Pakan * BK Asupan (Kg)`

Seluruh asupan dari berbagai macam pakan kemudian dijumlahkan secara kumulatif untuk mendapatkan nilai persentase aktual dari Formulasi.

### Tahap 3: Rasio Hijauan dan Konsentrat
Bahan pakan akan dikelompokkan ke dalam kategori (seperti Hijauan/Limbah basah sebagai Hijauan, dan Konsentrat sebagai Konsentrat). 
- *Formula Persentase*: `(Total BK Kategori / Total Keseluruhan BK Semua Pakan) * 100%`

### Tahap 4: Evaluasi
Sistem kemudian membandingkan akumulasi **Asupan Nutrisi Pakan** dengan standar baku **Kebutuhan Nutrisi Sapi**.
- `Selisih = Total Asupan Pakan - Total Kebutuhan Sapi`
- Ambang Toleransi (Threshold): `+/- 0.0001` (dibuat tipis untuk mendeteksi kelebihan sekecil apa pun)
- Status yang Diberikan: **Kurang** (jika selisih <= negatif_ambang), **Cukup** (jika sesuai angka presisi nol), **Berlebih** (jika selisih > positif_ambang).

## 📤 Output (Keluaran)

Hasil yang akan ditampilkan kepada pengguna di layar Hasil / Evaluasi diantaranya adalah:
1. **Rincian Evaluasi per Komponen Nutrisi**: Status tercapai atau tidaknya 4 pilar utama gizi (Bahan Kering, Protein, TDN, dan Energi ME) lengkap dengan angka numerik Kebutuhan, Pemberian (Pakan Aktual), Selisih (Kekurangan/Kelebihan), dan Status (Kurang/Cukup/Berlebih).
2. **Imbangan / Rasio**: Rasio persentase distribusi jenis pakan antara **Hijauan** banding **Konsentrat**.
3. **Kesimpulan Umum**: Pesan singkat konklusif. Jika semua indikator Cukup, maka aplikasi memberitahu bahwa *"Pakan sudah sesuai dengan kebutuhan sapi"*. Tapi jika ada indikator Kurang/Berlebih, aplikasi akan memberitahu *"Pakan belum mencukupi kebutuhan nutrisi"* atau *"Pakan cenderung berlebih pada beberapa komponen nutrisi"*.
