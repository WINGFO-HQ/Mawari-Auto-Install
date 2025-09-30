# Mawari Guardian Node Launcher (Docker)
**Created by [Kalawastra](https://t.me/Kalawastra)**

Script ini memudahkan Anda untuk menjalankan, mengelola, dan melakukan backup Guardian Node Mawari menggunakan Docker.

## 🚀 Fitur Utama
- **Cek & Instalasi Tools**: Memastikan `docker` dan `jq` sudah terpasang.
- **Luncurkan Node Baru**: Jalankan 1 atau lebih Guardian Node baru dengan owner wallet.
- **Cek Log Node**: Pantau log container sekaligus cek burner wallet address.
- **Jalankan Ulang Node**: Start container node yang berhenti/exited.
- **Stop/Hapus Node**: Hentikan sementara atau hapus permanen beserta cache datanya.
- **Backup Burner Wallets**: Backup semua burner wallet (alamat & private key) ke file `.json`.

## 📋 Prasyarat
- Sistem operasi berbasis Linux (Ubuntu 20.04+ direkomendasikan).
- `curl` dan `bash` sudah tersedia.
- Minimal 4GB RAM, 2 CPU core.

## 🔧 Cara Menggunakan
1. Clone atau download script:
   ```bash
   git clone https://github.com/WINGFO-HQ/Mawari-Auto-Install
   cd Mawari-Auto-Install
   chmod +x main.sh
   ./main.sh
   ```
