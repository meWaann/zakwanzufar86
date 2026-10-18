# ====================================
# 1. PENGATURAN PROJ
# ====================================
Sys.unsetenv("PROJ_LIB")
Sys.unsetenv("PROJ_DATA")
Sys.unsetenv("GDAL_DATA")

# ====================================
# 2. MEMANGGIL LIBRARY
# ====================================
library(sf)
library(terra)
library(dplyr)

# ====================================
# 3. MENENTUKAN FOLDER
# ====================================
folder_tubes <- "D:/Kuliah SMT5/Pemspa P Neo/TUBES"

setwd(folder_tubes)

folder_citra <- file.path(
  folder_tubes,
  "S2C_MSIL2A_20260529T022531_N0512_R046_T49MFM_20260529T061812.SAFE/S2C_MSIL2A_20260529T022531_N0512_R046_T49MFM_20260529T061812.SAFE/GRANULE/L2A_T49MFM_A009025_20260529T024756/IMG_DATA"
)

folder_batas <- file.path(
  folder_tubes,
  "batas_malang_fiks"
)

# ====================================
# 4. MEMERIKSA FOLDER
# ====================================
stopifnot(dir.exists(folder_citra))
stopifnot(dir.exists(folder_batas))

# ====================================
# 5. MENCARI FILE CITRA JP2
# ====================================
files <- list.files(
  folder_citra,
  pattern = "\\.jp2$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)

print(files)

# ====================================
# 6. MEMBACA BAND SENTINEL-2
# ====================================
ambil_band <- function(kode) {
  hasil <- grep(
    kode,
    files,
    value = TRUE
  )
  
  if (length(hasil) != 1) {
    stop(paste(
      "Jumlah file untuk band", kode, "=",
      length(hasil),
      ". Periksa hasil list.files()."
    ))
  }
  
  rast(hasil)
}

B03 <- ambil_band("R10m/T49MFM_20260529T022531_B03_10m")
B04 <- ambil_band("R10m/T49MFM_20260529T022531_B04_10m")
B08 <- ambil_band("R10m/T49MFM_20260529T022531_B08_10m")
B11 <- ambil_band("R20m/T49MFM_20260529T022531_B11_20m")

plot(B04, main = "Sentinel-2 Band B04")

# ====================================
# 7. MEMBACA BATAS ADMINISTRASI MALANG
# ====================================
shp_files <- list.files(
  folder_batas,
  pattern = "\\.shp$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)

print(shp_files)

if (length(shp_files) != 1) {
  stop("Pastikan folder batas_malang memiliki satu file SHP yang sesuai.")
}

malang <- st_read(shp_files[1])
malang <- st_make_valid(malang)

print(names(malang))
print(head(st_drop_geometry(malang)))

plot(
  st_geometry(malang),
  main = "Batas Administrasi Malang"
)

# ====================================
# 8. MENYAMAKAN CRS BATAS
# ====================================
batas <- terra::vect(malang)

if (!same.crs(batas, B11)) {
  batas <- terra::project(
    batas,
    terra::crs(B11)
  )
}

# ====================================
# 9. MENYAMAKAN RESOLUSI BAND
# ====================================
B03_new <- resample(B03, B11, method = "bilinear")
B04_new <- resample(B04, B11, method = "bilinear")
B08_new <- resample(B08, B11, method = "bilinear")

# ====================================
# 10. MENGGABUNGKAN BAND
# ====================================
citra <- c(
  B03_new,
  B04_new,
  B08_new,
  B11
)

names(citra) <- c("B03", "B04", "B08", "B11")

print(citra)

# ====================================
# 11. CROPPING DAN MASKING
# ====================================
citra_crop <- crop(citra, batas)
citra_mask <- mask(citra_crop, batas)

# ====================================
# 12. MENAMPILKAN HASIL CROPPING
# ====================================
plot(
  citra_mask$B04,
  main = "Hasil Cropping Sentinel-2 Malang"
)

plot(
  batas,
  add = TRUE,
  border = "red"
)

# ====================================
# 13. MENYIMPAN HASIL CROPPING
# ====================================
dir.create(
  file.path(folder_tubes, "output"),
  showWarnings = FALSE
)

writeRaster(
  citra_mask,
  file.path(folder_tubes, "output", "citra_malang.tif"),
  overwrite = TRUE
)

print(citra_mask)

# ==========================================
# 15. MEMBUAT FOLDER OUTPUT
# ==========================================

dir.create("output", showWarnings = FALSE)

# ====================================
# 14. MENGHITUNG NDVI
# ====================================
# NDVI = (NIR - Red) / (NIR + Red)
# B08 = NIR, B04 = Red

NDVI <- terra::ifel(
  (citra_mask$B08 + citra_mask$B04) == 0,
  NA,
  (citra_mask$B08 - citra_mask$B04) /
    (citra_mask$B08 + citra_mask$B04)
)

names(NDVI) <- "NDVI"

plot(
  NDVI,
  col = hcl.colors(100, "YlGn"),
  main = "NDVI - Vegetasi Kota Malang"
)

writeRaster(
  NDVI,
  "output/NDVI_malang.tif",
  overwrite = TRUE
)


# ====================================
# 15. MENGHITUNG NDBI
# ====================================
# NDBI = (SWIR - NIR) / (SWIR + NIR)
# B11 = SWIR, B08 = NIR

NDBI <- terra::ifel(
  (citra_mask$B11 + citra_mask$B08) == 0,
  NA,
  (citra_mask$B11 - citra_mask$B08) /
    (citra_mask$B11 + citra_mask$B08)
)

names(NDBI) <- "NDBI"

plot(
  NDBI,
  col = hcl.colors(100, "YlOrRd"),
  main = "NDBI - Area Terbangun Kota Malang"
)

writeRaster(
  NDBI,
  "output/NDBI_malang.tif",
  overwrite = TRUE
)


# ====================================
# 16. MENGHITUNG NDWI
# ====================================
# NDWI = (Green - NIR) / (Green + NIR)
# B03 = Green, B08 = NIR

NDWI <- terra::ifel(
  (citra_mask$B03 + citra_mask$B08) == 0,
  NA,
  (citra_mask$B03 - citra_mask$B08) /
    (citra_mask$B03 + citra_mask$B08)
)

names(NDWI) <- "NDWI"

plot(
  NDWI,
  col = hcl.colors(100, "Blues 3"),
  main = "NDWI - Badan Air Kota Malang"
)

writeRaster(
  NDWI,
  "output/NDWI_malang.tif",
  overwrite = TRUE
)


# ====================================
# 17. MENGHITUNG NDCI
# ====================================
# Rumus sesuai kode awal:
# NDCI = (Red - NIR) / (Red + NIR)
# B04 = Red, B08 = NIR

Red <- citra_mask$B04
NIR <- citra_mask$B08

NDCI <- terra::ifel(
  (Red + NIR) == 0,
  NA,
  (Red - NIR) / (Red + NIR)
)

names(NDCI) <- "NDCI"

plot(
  NDCI,
  col = colorRampPalette(
    c("steelblue4", "lightblue", "white", "gray70")
  )(100),
  main = "NDCI - Indeks Red-NIR Kota Malang"
)

writeRaster(
  NDCI,
  "output/NDCI_Cloud_Malang.tif",
  overwrite = TRUE
)


# ====================================
# 18. MEMERIKSA STATISTIK INDEKS
# ====================================

cat("\nSTATISTIK NDVI\n")
print(global(NDVI, c("min", "max", "mean"), na.rm = TRUE))

cat("\nSTATISTIK NDBI\n")
print(global(NDBI, c("min", "max", "mean"), na.rm = TRUE))

cat("\nSTATISTIK NDWI\n")
print(global(NDWI, c("min", "max", "mean"), na.rm = TRUE))

cat("\nSTATISTIK NDCI\n")
print(global(NDCI, c("min", "max", "mean"), na.rm = TRUE))


# ====================================
# 19. MENAMPILKAN EMPAT PETA
# ====================================

png(
  "output/4_indeks_malang.png",
  width = 2400,
  height = 1800,
  res = 200
)

par(mfrow = c(2, 2))

plot(
  NDVI,
  col = hcl.colors(100, "YlGn"),
  main = "NDVI - Vegetasi"
)

plot(
  NDBI,
  col = hcl.colors(100, "YlOrRd"),
  main = "NDBI - Area Terbangun"
)

plot(
  NDWI,
  col = hcl.colors(100, "Blues 3"),
  main = "NDWI - Badan Air"
)

plot(
  NDCI,
  col = colorRampPalette(
    c("steelblue4", "lightblue", "white", "gray70")
  )(100),
  main = "NDCI - Red-NIR"
)

dev.off()

par(mfrow = c(1, 1))

# ====================================
# 20. MEMBACA BATAS KECAMATAN MALANG
# ====================================

folder_kecamatan <- file.path(
  folder_tubes,
  "batas_kecamatan_malang"
)

# Mencari file SHP kecamatan
shp_kecamatan <- list.files(
  folder_kecamatan,
  pattern = "\\.shp$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)

print(shp_kecamatan)

if (length(shp_kecamatan) != 1) {
  stop("Pastikan folder berisi satu shapefile kecamatan yang sesuai.")
}

# Membaca shapefile
kecamatan <- st_read(shp_kecamatan[1])

# Memeriksa nama kolom
print(names(kecamatan))
print(head(st_drop_geometry(kecamatan)))

# Memperbaiki geometri
kecamatan <- st_make_valid(kecamatan)

# Menghapus geometri kosong
kecamatan <- kecamatan[
  !st_is_empty(kecamatan),
]


# ====================================
# 21. MEMERIKSA DAN MEMILIH WILAYAH
# ====================================

# PERHATIAN:
# Periksa hasil names(kecamatan) dan atributnya.
# Jangan filter sebelum mengetahui kolom kode
# kabupaten/kota dan nama kecamatan yang benar.

# Jika shapefile sudah khusus untuk kecamatan
# Kabupaten/Kota Malang, lanjutkan ke langkah 22.
# Jika berisi seluruh wilayah, lakukan filter
# menggunakan kolom dan kode yang benar terlebih dahulu.


# ====================================
# 22. MENYAMAKAN CRS
# ====================================

kecamatan <- st_transform(
  kecamatan,
  crs = terra::crs(NDVI)
)

kec <- terra::vect(kecamatan)

plot(
  kec,
  main = "Batas Kecamatan Malang"
)


# ====================================
# 23. MENYIAPKAN EMPAT RASTER INDEKS
# ====================================

# Memastikan raster indeks mempunyai grid
# yang sama dengan NDVI.

samakan_grid <- function(r, acuan) {
  if (!terra::same.crs(r, acuan)) {
    r <- terra::project(
      r,
      acuan,
      method = "bilinear"
    )
  } else if (!terra::compareGeom(
    r,
    acuan,
    stopOnError = FALSE
  )) {
    r <- terra::resample(
      r,
      acuan,
      method = "bilinear"
    )
  }
  
  r
}

NDBI_fix <- samakan_grid(NDBI, NDVI)
NDWI_fix <- samakan_grid(NDWI, NDVI)
NDCI_fix <- samakan_grid(NDCI, NDVI)

indeks_zonal <- c(
  NDVI,
  NDBI_fix,
  NDWI_fix,
  NDCI_fix
)

names(indeks_zonal) <- c(
  "NDVI",
  "NDBI",
  "NDWI",
  "NDCI"
)

print(indeks_zonal)


# ====================================
# 24. MENGHITUNG ZONAL STATISTICS
# ====================================

# Mengambil nama kecamatan dari atribut.
# Ganti "WADMKC" jika nama kolom kecamatan
# pada shapefile milikmu berbeda.

nama_kolom <- names(kecamatan)

print(nama_kolom)

# GANTI WADMKC dengan nama kolom kecamatan
# yang benar setelah memeriksa names(kecamatan).

if (!"WADMKC" %in% nama_kolom) {
  stop("Kolom WADMKC tidak ditemukan. Periksa names(kecamatan), lalu sesuaikan nama kolom kecamatan.")
}

zonal <- data.frame(
  Kecamatan = kecamatan[["WADMKC"]]
)

statistik <- list(
  Mean = mean,
  Minimum = min,
  Maximum = max,
  Median = median,
  SD = sd
)

for (nama in names(indeks_zonal)) {
  for (stat in names(statistik)) {
    
    hasil <- terra::extract(
      indeks_zonal[[nama]],
      kec,
      fun = statistik[[stat]],
      na.rm = TRUE
    )
    
    zonal[[paste(nama, stat, sep = "_")]] <- hasil[[2]]
  }
}

# Melihat tabel
View(zonal)

print(head(zonal))


# ====================================
# 25. MENYIMPAN ZONAL STATISTICS
# ====================================

folder_output <- file.path(
  folder_tubes,
  "output"
)

dir.create(
  folder_output,
  showWarnings = FALSE,
  recursive = TRUE
)

write.csv(
  zonal,
  file.path(
    folder_output,
    "Zonal_Statistics_Malang.csv"
  ),
  row.names = FALSE
)

cat("Zonal statistics tersimpan di:\n")
cat(file.path(
  folder_output,
  "Zonal_Statistics_Malang.csv"
))