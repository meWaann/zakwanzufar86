# EVALUASI TENGAH SEMESTER – ANALISIS INDEKS SPEKTRAL & KLASIFIKASI TUTUPAN LAHAN

---

## PENDAHULUAN

### Latar Belakang
Perkembangan teknologi penginderaan jauh dan Sistem Informasi Geografis (SIG) memungkinkan pengolahan serta analisis informasi permukaan bumi secara lebih efektif. Salah satu pemanfaatannya adalah analisis tutupan lahan menggunakan citra satelit untuk mengidentifikasi vegetasi, kawasan terbangun, dan badan air.

Kegiatan ini menggunakan citra Sentinel-2 Level-2A untuk menganalisis tutupan lahan di wilayah Kota Malang. Pemilihan Kota Malang sebagai wilayah kajian didasarkan pada ketertarikan untuk mengenal dan mengkaji lebih lanjut karakteristik wilayah tersebut melalui penginderaan jauh.

Pengolahan citra dilakukan menggunakan perangkat lunak R melalui perhitungan empat indeks spektral, yaitu NDVI untuk vegetasi, NDBI untuk kawasan terbangun, NDWI untuk perairan, dan NDCI untuk klasifikasi awan. Hasil perhitungan indeks digunakan dalam proses klasifikasi berdasarkan nilai ambang batas (*threshold*) sehingga menghasilkan peta komposit dengan kelas tutupan lahan.

Selain klasifikasi, dilakukan analisis *zonal statistics* untuk memperoleh nilai rata-rata, minimum, maksimum, median, dan standar deviasi setiap indeks pada masing-masing kecamatan. Hasil analisis disajikan dalam bentuk peta dan tabel statistik. Visualisasi menggunakan R Shiny dan Leaflet juga diterapkan untuk mendukung penyajian hasil analisis dalam bentuk peta interaktif. Seluruh hasil pengerjaan proyek diunggah ke GitHub sebagai media penyimpanan dan pengelolaan berkas proyek secara daring.

### Rumusan Masalah
1. Bagaimana melakukan pemotongan (*cropping*) citra Sentinel-2 Level-2A berdasarkan batas administrasi wilayah Malang?
2. Bagaimana menghitung indeks spektral NDVI, NDBI, NDWI, dan NDCI dari citra hasil pemotongan?
3. Bagaimana menentukan nilai ambang batas (*threshold*) untuk mengklasifikasikan tutupan lahan menjadi empat kelas, yaitu vegetasi, kawasan terbangun, perairan, dan awan?
4. Bagaimana menghasilkan peta komposit klasifikasi tutupan lahan dengan warna yang berbeda untuk setiap kelas?
5. Bagaimana menghitung statistik NDVI, NDBI, NDWI, dan NDCI pada setiap kecamatan yang meliputi nilai rata-rata, minimum, maksimum, median, dan standar deviasi?
6. Bagaimana menyajikan hasil analisis spasial melalui peta dan tabel statistik serta visualisasi peta interaktif menggunakan R Shiny dan Leaflet?

### Tujuan
1. Melakukan pemotongan (*cropping*) citra Sentinel-2 Level-2A berdasarkan batas administrasi wilayah Malang.
2. Menghitung indeks spektral NDVI, NDBI, NDWI, dan NDCI dari citra hasil pemotongan.
3. Menentukan nilai ambang batas (*threshold*) untuk mengklasifikasikan tutupan lahan menjadi empat kelas, yaitu vegetasi, kawasan terbangun, perairan, dan awan.
4. Menghasilkan peta komposit klasifikasi tutupan lahan dengan warna yang berbeda untuk setiap kelas.
5. Menghitung statistik NDVI, NDBI, NDWI, dan NDCI pada setiap kecamatan yang meliputi nilai rata-rata, minimum, maksimum, median, dan standar deviasi.
6. Menyajikan hasil analisis spasial dalam bentuk peta komposit, tabel statistik zonal, serta visualisasi peta interaktif menggunakan R Shiny dan Leaflet.

---

## TINJAUAN PUSTAKA

### Pengindraan Jauh
Penginderaan jauh merupakan teknologi untuk memperoleh informasi mengenai objek atau kondisi permukaan bumi tanpa melakukan kontak langsung dengan objek tersebut. Informasi diperoleh melalui perekaman energi elektromagnetik yang dipantulkan atau dipancarkan oleh objek menggunakan sensor pada satelit atau wahana lainnya. Setiap objek di permukaan bumi memiliki karakteristik respons spektral yang berbeda sehingga dapat dianalisis untuk membedakan berbagai jenis tutupan lahan.

Dalam penelitian ini, penginderaan jauh digunakan untuk mengidentifikasi karakteristik tutupan lahan di Kota Malang berdasarkan citra satelit. Analisis dilakukan dengan memanfaatkan perbedaan respons spektral vegetasi, kawasan terbangun, dan badan air untuk menghasilkan informasi spasial yang dapat divisualisasikan dalam bentuk peta.

### Citra Satelit Sentinel-2 Level-2A
Sentinel-2 merupakan misi penginderaan jauh milik program Copernicus yang menyediakan citra multispektral untuk pemantauan permukaan bumi. Produk Sentinel-2 Level-2A menyediakan data reflektansi permukaan yang telah melalui koreksi atmosfer dari produk Level-1C. Produk ini juga mencakup informasi tambahan, seperti peta klasifikasi objek (*Scene Classification Layer* atau SCL), aerosol, dan uap air.

### Indeks Spektral untuk Analisis Tutupan Lahan
Indeks spektral merupakan kombinasi matematis dari nilai reflektansi dua atau lebih kanal citra satelit. Indeks ini membantu menonjolkan karakteristik objek tertentu sehingga informasi vegetasi, kawasan terbangun, atau badan air lebih mudah dianalisis.

#### Normalized Difference Vegetation Index (NDVI)
NDVI merupakan indeks yang digunakan untuk mengidentifikasi keberadaan dan kondisi relatif vegetasi melalui perbedaan reflektansi kanal inframerah dekat dan kanal merah.
$$\text{NDVI} = \frac{\text{NIR} - \text{Red}}{\text{NIR} + \text{Red}} = \frac{\text{B08} - \text{B04}}{\text{B08} + \text{B04}}$$

#### Normalized Difference Built-up Index (NDBI)
NDBI digunakan untuk membantu mengidentifikasi kawasan terbangun berdasarkan perbedaan reflektansi kanal SWIR dan NIR.
$$\text{NDBI} = \frac{\text{SWIR} - \text{NIR}}{\text{SWIR} + \text{NIR}} = \frac{\text{B11} - \text{B08}}{\text{B11} + \text{B08}}$$

#### Normalized Difference Water Index (NDWI)
NDWI merupakan indeks yang digunakan untuk menonjolkan badan air melalui perbedaan reflektansi kanal hijau dan inframerah dekat.
$$\text{NDWI} = \frac{\text{Green} - \text{NIR}}{\text{Green} + \text{NIR}} = \frac{\text{B03} - \text{B08}}{\text{B03} + \text{B08}}$$

#### Normalized Difference Cloud Index (NDCI)
Nilai NDCI dapat digunakan untuk mengukur dan mengklasifikasikan kepadatan awan pada suatu lokasi dengan memanfaatkan kanal spektral tertentu.

### Klasifikasi Tutupan Lahan Menggunakan Threshold
Klasifikasi tutupan lahan merupakan proses pengelompokan piksel citra ke dalam kelas tertentu berdasarkan karakteristik spektralnya. Pada proyek ini, klasifikasi dilakukan menggunakan metode *threshold*, yaitu menentukan batas nilai indeks untuk membedakan kelas yang diinginkan. Hasil klasifikasi kemudian digabungkan menjadi peta komposit dengan warna berbeda untuk setiap kelas.

---

## METODOLOGI

### Alat dan Bahan
- **Laptop**: Perangkat keras untuk menjalankan pengolahan data.
- **Copernicus Browser**: Sumber akuisisi citra Sentinel-2 Level-2A.
- **Ina-Geoportal**: Sumber data batas administrasi.
- **QGIS**: Perangkat lunak verifikasi data spasial.
- **R / RStudio**: Lingkungan pemrograman spasial dan pembuatan WebGIS.
- **GitHub**: Repositori kode dan penyimpanan proyek daring.

### Langkah Kerja

#### 1. Akuisisi Data
Pengumpulan data citra satelit Sentinel-2 Level-2A dan data batas administrasi Kota Malang.

#### 2. Persiapan dan Pemrosesan Awal
- Pemeriksaan data menggunakan QGIS.
- Pengaturan *library* dan *environment* di RStudio.
- Penyesuaian grid resolusi spasial antar kanal citra (B03, B04, B08, B11).

#### 3. Cropping dan Masking
Memotong citra sesuai batas poligon administrasi Kota Malang.

#### 4. Perhitungan Indeks Spektral
Menghitung raster NDVI, NDBI, NDWI, dan NDCI dari kanal-kanal citra yang telah dipotong.

#### 5. Klasifikasi Tutupan Lahan
Penerapan kondisi bertingkat (*nested conditions*) berdasarkan nilai *threshold* untuk membentuk 5 kelas tutupan lahan.

#### 6. Analisis Zonal Statistics
Mengekstrak statistik deskriptif (mean, min, max, median, std dev) per wilayah kecamatan.

#### 7. Visualisasi WebGIS Interaktif
Membangun dashboard R Shiny dan Leaflet untuk menyajikan peta spasial dan tabel interaktif.

---

## HASIL DAN ANALISIS

### Hasil Pengolahan

#### 1. Hasil Pemotongan Citra
Hasil pemotongan (*cropping*) citra Sentinel-2 berdasarkan poligon batas administrasi Kota Malang:

![Hasil Cropping](output/citra_malang.png)

#### 2. Hasil Perhitungan Indeks Spektral
Peta visualisasi indeks spektral NDVI, NDWI, NDBI, dan NDCI:

![Hasil Indeks Spektral](output/4_indeks_malang.png)

#### 3. Hasil Klasifikasi Tutupan Lahan
Peta tematik tutupan lahan berdasarkan kombinasi *thresholding* indeks spektral:

![Klasifikasi Tutupan Lahan](output/Klasifikasi_Tutupan_Lahan.tif)

#### 4. Hasil Zonal Statistics
Tabel dan grafik ringkasan statistik zonal per kecamatan di Kota Malang:

![Zonal Statistics](output/Zonal_Statistics_Malang.csv)

#### 5. Hasil Visualisasi
