#!/bin/bash

# ==========================================
#  Mawari Guardian Node Launcher (Docker)
#  Created by Kalawastra
#  Telegram: https://t.me/Kalawastra
#  Channel: https://t.me/infomindao
# ==========================================

MNTESTNET_IMAGE="us-east4-docker.pkg.dev/mawarinetwork-dev/mwr-net-d-car-uses4-public-docker-registry-e62e/mawari-node:latest"
MAWARI_CONTAINER_PREFIX="mawari-gn-" 

GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
NC=$'\033[0m' 

show_header() {
    clear
    echo -e "${BLUE}======================================================"
    echo -e "      Mawari Guardian Node Launcher (Docker)          "
    echo -e "${RED}              Created by ${GREEN}Kalawastra${NC}"
    echo -e "${YELLOW}        Telegram: https://t.me/Kalawastra${NC}"
    echo -e "${CYAN}        Channel : https://t.me/infomindao${NC}"
    echo -e "======================================================${NC}"
}

check_and_install_requirements() {
    show_header
    echo -e "${CYAN}--- MEMULAI CEK & INSTALASI PERSYARATAN (DOCKER & JQ) ---${NC}"
    
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker sudah terinstal. Melewati instalasi.${NC}"
    else
        echo -e "${RED}❌ Docker belum terinstal. Memulai instalasi Docker...${NC}"
        
        echo -e "${YELLOW}🛠️ Menginstal paket yang diperlukan...${NC}"

        sudo apt update > /dev/null 2>&1
        sudo apt install -y ca-certificates curl gnupg lsb-release jq > /dev/null 2>&1

        echo -e "${YELLOW}🛠️ Menambahkan Docker GPG key...${NC}"
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        echo -e "${YELLOW}🛠️ Menambahkan repositori Docker...${NC}"
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        echo -e "${YELLOW}🛠️ Menginstal Docker Engine...${NC}"
        sudo apt update > /dev/null 2>&1
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1

        echo -e "${YELLOW}🛠️ Menambahkan user saat ini ke grup 'docker'...${NC}"
        sudo usermod -aG docker "$USER"
        
        echo ""
        echo -e "${GREEN}🎉 INSTALASI DOCKER SELESAI!${NC}"
        echo -e "${RED}⚠️ PENTING: Anda harus LOGOUT dan LOGIN kembali agar perubahan grup 'docker' diterapkan.${NC}"
    fi

    if command -v jq &> /dev/null; then
        echo -e "${GREEN}✅ jq (JSON processor) sudah terinstal.${NC}"
    else
        echo -e "${RED}❌ jq belum terinstal. Menginstal jq...${NC}"
        sudo apt update > /dev/null 2>&1
        sudo apt install -y jq > /dev/null 2>&1
        echo -e "${GREEN}🎉 Instalasi jq selesai.${NC}"
    fi

    echo ""
    echo -e "${CYAN}--- CEK PERSYARATAN SELESAI ---${NC}"
    read -p "Tekan Enter untuk melanjutkan ke menu utama..."
}

check_running_nodes() {
    show_header
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ ERROR: Docker belum terinstal atau user belum diizinkan. Silakan pilih Opsi 1 atau LOGOUT/LOGIN kembali.${NC}"
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 1
    fi
    
    echo -e "${CYAN}--- DAFTAR NODE MAWARI YANG AKTIF ---${NC}"
    
    NODE_STATUS_LINES=$(docker ps -a --filter "name=$MAWARI_CONTAINER_PREFIX" --format "{{.Names}}\t{{.Status}}" | sort -V)

    if [ -z "$NODE_STATUS_LINES" ]; then
        echo -e "${YELLOW}TIDAK ADA Guardian Node Mawari yang terdeteksi.${NC}"
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 1
    fi

    NODE_ARRAY=()
    echo -e "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------${NC}"
    printf "${CYAN}%-5s | %-18s | %-45s | %s${NC}\n" "No." "Container Name" "Status" "Burner Wallet Address (Dibutuhkan Token)"
    echo -e "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------${NC}"

    i=0
    echo "$NODE_STATUS_LINES" | while IFS=$'\t' read -r NODE_NAME STATUS; do
        i=$((i+1))
        NODE_ARRAY+=("$NODE_NAME")
        
        NODE_NUM=$(echo "$NODE_NAME" | sed "s/$MAWARI_CONTAINER_PREFIX//")
        CACHE_DIR="$HOME/mawari-node-$NODE_NUM"
        CACHE_FILE="$CACHE_DIR/flohive-cache.json"
        
        BURNER_ADDR="${YELLOW}TIDAK DITEMUKAN${NC}"
        COLOR_STATUS="${RED}$STATUS${NC}"
        
        if [[ "$STATUS" == *Up* ]]; then
            COLOR_STATUS="${GREEN}$STATUS${NC}"
        fi

        if [ -f "$CACHE_FILE" ]; then
            JSON_CONTENT=$(sudo cat "$CACHE_FILE" 2>/dev/null)
            
            if [ -n "$JSON_CONTENT" ]; then
                BURNER_ADDR_RAW=$(echo "$JSON_CONTENT" | jq -r '.burnerWallet.address // "FILE RUSAK/TUNGGU NODE"' 2>/dev/null)
                
                if [ -n "$BURNER_ADDR_RAW" ] && [ "$BURNER_ADDR_RAW" != "null" ] && [ "$BURNER_ADDR_RAW" != "FILE RUSAK/TUNGGU NODE" ]; then
                    BURNER_ADDR="${GREEN}$BURNER_ADDR_RAW${NC}"
                else
                    BURNER_ADDR="${YELLOW}MEMUAT/TUNGGU CACHE${NC}"
                fi
            else
                BURNER_ADDR="${YELLOW}MEMUAT/TUNGGU CACHE${NC}"
            fi
        fi
        
        printf "%-5s | %-18s | %-45s | %s\n" "$i" "$NODE_NAME" "$COLOR_STATUS" "$BURNER_ADDR"
    done

    NODE_ARRAY=($(docker ps -a --filter "name=$MAWARI_CONTAINER_PREFIX" --format "{{.Names}}" | sort -V))
    
    echo -e "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------${NC}"

    echo ""
    read -p "Masukkan ${YELLOW}Nomor node${NC} yang log-nya ingin Anda lihat, atau tekan '${YELLOW}x${NC}' untuk kembali ke menu: " CHOICE
    
    if [[ "$CHOICE" == "x" || "$CHOICE" == "X" ]]; then
        return 0
    fi

    IFS=',' read -r -a SELECTED_INDICES <<< "$CHOICE"
    
    if [ ${#SELECTED_INDICES[@]} -ne 1 ] || ! [[ "${SELECTED_INDICES[0]}" =~ ^[0-9]+$ ]] || [ "${SELECTED_INDICES[0]}" -lt 1 ] || [ "${SELECTED_INDICES[0]}" -gt ${#NODE_ARRAY[@]} ]; then
        echo -e "${RED}❌ ERROR: Hanya satu node yang dapat dilihat log-nya. Pilihan tidak valid.${NC}"
        return 0
    fi

    SELECTED_NODE=${NODE_ARRAY[${SELECTED_INDICES[0]}-1]}
    
    echo ""
    echo -e "${BLUE}------------------------------------------------------------------------${NC}"
    echo -e "    ${CYAN}MENAMPILKAN LOG NODE: $SELECTED_NODE${NC} (Tekan ${RED}Ctrl+C${NC} untuk keluar)"
    echo -e "${BLUE}------------------------------------------------------------------------${NC}"
    docker logs -f "$SELECTED_NODE"
}

restart_stopped_nodes() {
    show_header
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ ERROR: Docker belum terinstal. Silakan pilih Opsi 1.${NC}"
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 1
    fi
    
    echo -e "${CYAN}--- KONTROL NODE: JALANKAN ULANG NODE YANG BERHENTI ---${NC}"
    
    STOPPED_NODES=$(docker ps -a --filter "name=$MAWARI_CONTAINER_PREFIX" --filter "status=exited" --format "{{.Names}}" | sort -V)
    STOPPED_NODES_2=$(docker ps -a --filter "name=$MAWARI_CONTAINER_PREFIX" --filter "status=created" --format "{{.Names}}" | sort -V)
    ALL_STOPPED_NODES=$(echo -e "$STOPPED_NODES\n$STOPPED_NODES_2" | sort -u -V)

    if [ -z "$ALL_STOPPED_NODES" ]; then
        echo -e "${GREEN}TIDAK ADA Guardian Node Mawari yang berstatus ${RED}BERHENTI (Stopped/Exited)${GREEN} yang terdeteksi.${NC}"
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 1
    fi

    NODE_ARRAY=($ALL_STOPPED_NODES)
    echo "Ditemukan ${#NODE_ARRAY[@]} node yang berhenti."
    echo "Pilih ${YELLOW}nomor node${NC} (pisahkan dengan koma untuk multipel, mis. '1,5,10') untuk ${BLUE}dijalankan ulang${NC}, atau tekan '${YELLOW}x${NC}' untuk kembali:"

    i=0
    for NODE_NAME in "${NODE_ARRAY[@]}"; do
        i=$((i+1))
        echo -e "$i) ${NODE_NAME}"
    done

    read -p "Masukkan ${YELLOW}Nomor(s)${NC} atau '${YELLOW}x${NC}': " CHOICE

    if [[ "$CHOICE" == "x" || "$CHOICE" == "X" ]]; then
        return 0
    fi

    IFS=',' read -r -a SELECTED_INDICES <<< "$CHOICE"
    
    VALID_NODES=()
    VALID_CHOICE=true
    for index in "${SELECTED_INDICES[@]}"; do
        index=$(echo "$index" | xargs)
        
        if ! [[ "$index" =~ ^[0-9]+$ ]] || [ "$index" -lt 1 ] || [ "$index" -gt ${#NODE_ARRAY[@]} ]; then
            echo -e "${RED}❌ ERROR: Nomor node '$index' tidak valid. Mohon masukkan angka sesuai daftar.${NC}"
            VALID_CHOICE=false
            break
        fi
        VALID_NODES+=("${NODE_ARRAY[$index-1]}")
    done

    if ! $VALID_CHOICE || [ ${#VALID_NODES[@]} -eq 0 ]; then
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 0
    fi

    echo ""
    echo -e "${YELLOW}🛠️ Memulai menjalankan ulang ${#VALID_NODES[@]} node...${NC}"
    for SELECTED_NODE in "${VALID_NODES[@]}"; do
        echo -e "  -> Menjalankan ulang $SELECTED_NODE..."
        docker start "$SELECTED_NODE" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "      ${GREEN}✅ $SELECTED_NODE berhasil dijalankan ulang.${NC}"
        else
            echo -e "      ${RED}❌ Gagal menjalankan ulang $SELECTED_NODE. Cek statusnya.${NC}"
        fi
    done

    read -p "Tekan Enter untuk kembali ke menu utama..."
}

stop_node() {
    show_header
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ ERROR: Docker belum terinstal. Silakan pilih Opsi 1.${NC}"
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 1
    fi
    
    echo -e "${CYAN}--- KONTROL NODE: HENTIKAN ATAU HAPUS ---${NC}"
    
    ALL_NODES=$(docker ps -a --filter "name=$MAWARI_CONTAINER_PREFIX" --format "{{.Names}}" | sort -V)

    if [ -z "$ALL_NODES" ]; then
        echo -e "${YELLOW}TIDAK ADA Guardian Node Mawari yang terdeteksi.${NC}"
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 1
    fi

    NODE_ARRAY=($ALL_NODES)
    echo "Pilih ${YELLOW}nomor node${NC} (pisahkan dengan koma untuk multipel, mis. '1,5,10') atau tekan '${YELLOW}x${NC}' untuk kembali:"

    i=0
    for NODE_NAME in "${NODE_ARRAY[@]}"; do
        i=$((i+1))
        STATUS=$(docker inspect --format='{{.State.Status}}' "$NODE_NAME" 2>/dev/null)
        
        COLOR_STATUS="${RED}$STATUS${NC}"
        if [ "$STATUS" == "running" ]; then
            COLOR_STATUS="${GREEN}$STATUS${NC}"
        fi
        
        echo -e "$i) ${NODE_NAME} (Status: ${COLOR_STATUS})"
    done

    read -p "Masukkan ${YELLOW}Nomor(s)${NC} atau '${YELLOW}x${NC}': " CHOICE

    if [[ "$CHOICE" == "x" || "$CHOICE" == "X" ]]; then
        return 0
    fi

    IFS=',' read -r -a SELECTED_INDICES <<< "$CHOICE"
    
    VALID_NODES=()
    VALID_CHOICE=true
    for index in "${SELECTED_INDICES[@]}"; do
        index=$(echo "$index" | xargs)
        
        if ! [[ "$index" =~ ^[0-9]+$ ]] || [ "$index" -lt 1 ] || [ "$index" -gt ${#NODE_ARRAY[@]} ]; then
            echo -e "${RED}❌ ERROR: Nomor node '$index' tidak valid. Mohon masukkan angka sesuai daftar.${NC}"
            VALID_CHOICE=false
            break
        fi
        VALID_NODES+=("${NODE_ARRAY[$index-1]}")
    done

    if ! $VALID_CHOICE || [ ${#VALID_NODES[@]} -eq 0 ]; then
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 0
    fi

    echo ""
    echo -e "Anda memilih ${#VALID_NODES[@]} container."
    echo -e "1) ${YELLOW}Hentikan (Stop) Node(s)${NC} (Dapat dihidupkan kembali nanti)"
    echo -e "2) ${RED}Hapus (Remove) Node(s) & Data Cache${NC} (Permanen)"
    read -p "Pilih tindakan (1 atau 2): " ACTION_CHOICE

    if [ "$ACTION_CHOICE" == "1" ]; then
        echo ""
        echo -e "${YELLOW}🛠️ Memulai penghentian ${#VALID_NODES[@]} node...${NC}"
        for SELECTED_NODE in "${VALID_NODES[@]}"; do
            echo -e "  -> Menghentikan $SELECTED_NODE..."
            docker stop "$SELECTED_NODE" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo -e "      ${GREEN}✅ $SELECTED_NODE berhasil dihentikan.${NC}"
            else
                echo -e "      ${RED}❌ Gagal menghentikan $SELECTED_NODE. Mungkin sudah berhenti.${NC}"
            fi
        done
        
    elif [ "$ACTION_CHOICE" == "2" ]; then
        read -r -p "${RED}⚠️ PERINGATAN: Menghapus ${#VALID_NODES[@]} node dan data cache bersifat PERMANEN. Lanjutkan? (y/n): ${NC}" CONFIRM
        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${YELLOW}🛠️ Memulai penghapusan ${#VALID_NODES[@]} node...${NC}"
            for SELECTED_NODE in "${VALID_NODES[@]}"; do
                NODE_NUM=$(echo "$SELECTED_NODE" | sed "s/$MAWARI_CONTAINER_PREFIX//")
                CACHE_DIR="$HOME/mawari-node-$NODE_NUM"
                
                echo -e "  -> Menghapus $SELECTED_NODE dan data cache $CACHE_DIR..."
                
                docker rm -f "$SELECTED_NODE" > /dev/null 2>&1
                rm -rf "$CACHE_DIR"
                
                if [ $? -eq 0 ]; then
                    echo -e "      ${GREEN}✅ $SELECTED_NODE dan datanya berhasil dihapus.${NC}"
                else
                    echo -e "      ${RED}❌ Gagal menghapus $SELECTED_NODE atau datanya.${NC}"
                fi
            done
        else
            echo -e "${YELLOW}Operasi penghapusan dibatalkan.${NC}"
        fi
    else
        echo -e "${RED}❌ Pilihan tindakan tidak valid. Kembali ke menu utama.${NC}"
    fi
    read -p "Tekan Enter untuk kembali ke menu utama..."
}

run_new_nodes() {
    show_header
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ ERROR: Docker belum terinstal atau user belum diizinkan. Silakan pilih Opsi 1 atau LOGOUT/LOGIN kembali.${NC}"
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 1
    fi
    
    echo -e "${CYAN}--- LUNCURKAN NODE BARU ---${NC}"
    read -p "Masukkan jumlah Guardian Node BARU yang ingin Anda jalankan: " NUM_NODES
    if ! [[ "$NUM_NODES" =~ ^[0-9]+$ ]] || [ "$NUM_NODES" -le 0 ]; then
        echo -e "${RED}❌ ERROR: Input tidak valid. Harap masukkan angka positif.${NC}"
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 1
    fi

    echo ""
    echo -e "${CYAN}Pilihan Owner Wallet (yang memiliki NFT Guardian):${NC}"
    echo "1) Gunakan owner wallet yang ${GREEN}SAMA${NC} untuk SEMUA node."
    echo "2) Gunakan owner wallet yang ${YELLOW}BERBEDA${NC} untuk SETIAP node."
    read -p "Pilih (1 atau 2): " OWNER_CHOICE

    if [[ "$OWNER_CHOICE" != "1" && "$OWNER_CHOICE" != "2" ]]; then
        echo -e "${RED}❌ ERROR: Pilihan tidak valid. Harap masukkan 1 atau 2.${NC}"
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 1
    fi

    OWNER_ADDRESSES=()
    if [ "$OWNER_CHOICE" == "1" ]; then
        read -p "Masukkan Owner Wallet Address ${GREEN}TUNGGAL${NC} (mis. 0x123...abc): " SINGLE_OWNER
        if [[ -z "$SINGLE_OWNER" ]]; then
            echo -e "${RED}❌ ERROR: Alamat tidak boleh kosong.${NC}"
            read -p "Tekan Enter untuk kembali ke menu utama..."
            return 1
        fi
        for ((i=1; i<=$NUM_NODES; i++)); do
            OWNER_ADDRESSES+=("$SINGLE_OWNER")
        done
    else
        for ((i=1; i<=$NUM_NODES; i++)); do
            read -p "Masukkan Owner Wallet Address untuk Node #${CYAN}$i${NC}: " UNIQUE_OWNER
            if [[ -z "$UNIQUE_OWNER" ]]; then
                echo -e "${RED}❌ ERROR: Alamat tidak boleh kosong.${NC}"
                read -p "Tekan Enter untuk kembali ke menu utama..."
                return 1
            fi
            OWNER_ADDRESSES+=("$UNIQUE_OWNER")
        done
    fi

    echo ""
    echo -e "${BLUE}------------------------------------------------------${NC}"
    echo -e "Memulai proses peluncuran ${GREEN}$NUM_NODES${NC} Guardian Node..."
    echo -e "${BLUE}------------------------------------------------------${NC}"
    echo ""

    for ((i=1; i<=$NUM_NODES; i++)); do
        CURRENT_OWNER=${OWNER_ADDRESSES[$i-1]}
        
        NODE_NUM=1
        while docker ps -a --format "{{.Names}}" | grep -q "$MAWARI_CONTAINER_PREFIX$NODE_NUM"; do
            NODE_NUM=$((NODE_NUM + 1))
        done
        
        NODE_NAME="$MAWARI_CONTAINER_PREFIX$NODE_NUM"
        CACHE_DIR="$HOME/mawari-node-$NODE_NUM"
        CACHE_FILE="$CACHE_DIR/flohive-cache.json"

        echo -e "${YELLOW}▶️ Menjalankan Node #$NODE_NUM (Container: $NODE_NAME)${NC}"
        echo -e "    Owner Address: ${CYAN}$CURRENT_OWNER${NC}"
        echo -e "    Cache Folder: ${CYAN}$CACHE_DIR${NC}"

        mkdir -p "$CACHE_DIR"

        docker run -d --pull always \
            -v "$CACHE_DIR":/app/cache \
            -e OWNERS_ALLOWLIST="$CURRENT_OWNER" \
            --name "$NODE_NAME" \
            "$MNTESTNET_IMAGE" > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Node #$NODE_NUM berhasil diluncurkan.${NC}"
            
            echo -e "${YELLOW}🛠️ Menunggu 10 detik untuk pembuatan cache dan menambahkan Owner Wallet...${NC}"
            sleep 10
            
            if ! command -v jq &> /dev/null; then
                echo -e "${RED}❌ ERROR: JQ tidak ditemukan. Tidak dapat menyimpan Owner Wallet.${NC}"
            elif [ -f "$CACHE_FILE" ]; then

                sudo cat "$CACHE_FILE" 2>/dev/null | \
                jq --arg owner "$CURRENT_OWNER" '. + { ownerWallet: $owner }' | \
                sudo tee "$CACHE_FILE" > /dev/null
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✅ Owner Wallet berhasil ditambahkan ke $CACHE_FILE.${NC}"
                else
                    echo -e "${RED}❌ GAGAL menambahkan Owner Wallet ke $CACHE_FILE.${NC} Cek izin file atau format JSON."
                fi
            else
                echo -e "${YELLOW}⚠️ $CACHE_FILE tidak ditemukan setelah 5 detik. Node mungkin belum sepenuhnya siap.${NC}"
            fi

        else
            echo -e "${RED}❌ GAGAL meluncurkan Node #$NODE_NUM. Cek error di atas.${NC}"
        fi
        echo ""
    done
    read -p "Tekan Enter untuk kembali ke menu utama..."
}

backup_all_burner_wallets() {
    show_header
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ ERROR: jq belum terinstal. Silakan pilih Opsi 1 di Menu Utama.${NC}"
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 1
    fi

    BACKUP_FILE="$HOME/mawari_burner_wallets_backup_$(date +%Y%m%d_%H%M%S).json"
    TEMP_ARRAY_FILE=$(mktemp)
    
    echo -e "${CYAN}--- MEMULAI PROSES BACKUP BURNER WALLET ---${NC}"
    echo -e "${YELLOW}Mencari file flohive-cache.json yang berisi kunci privat...${NC}"
    echo "[" > "$TEMP_ARRAY_FILE" 

    FIRST=true
    
    find "$HOME" -maxdepth 1 -type d -name "mawari-node-*" | while read -r CACHE_DIR; do
        NODE_NUM=$(basename "$CACHE_DIR" | sed 's/mawari-node-//')
        CACHE_FILE="$CACHE_DIR/flohive-cache.json"

        if [ -f "$CACHE_FILE" ]; then
            JSON_CONTENT=$(sudo cat "$CACHE_FILE" 2>/dev/null)
            
            if [ -n "$JSON_CONTENT" ]; then
                BACKUP_ENTRY=$(echo "$JSON_CONTENT" | jq --arg nodeName "$MAWARI_CONTAINER_PREFIX$NODE_NUM" '
                    if .burnerWallet.privateKey and .burnerWallet.address then
                        {
                            nodeName: $nodeName,
                            ownerWallet: (.ownerWallet // "OWNER_TIDAK_TERCATAT"),
                            burnerWallet: .burnerWallet
                        }
                    else
                        empty
                    end
                ' 2>/dev/null)

                if [ -n "$BACKUP_ENTRY" ] && [ "$BACKUP_ENTRY" != "null" ]; then
                    if $FIRST; then
                        FIRST=false
                    else
                        echo "," >> "$TEMP_ARRAY_FILE" 
                    fi
                    
                    echo "$BACKUP_ENTRY" >> "$TEMP_ARRAY_FILE"
                    echo -e "${GREEN}✅ Node #$NODE_NUM${NC} (${MAWARI_CONTAINER_PREFIX}$NODE_NUM) berhasil dibackup."
                else
                    echo -e "${YELLOW}⚠️ Node #$NODE_NUM: File cache ada, tetapi privateKey tidak valid/ditemukan.${NC}"
                fi
            fi
        fi
    done

    echo "]" >> "$TEMP_ARRAY_FILE" 

    if ! jq -e '. | length > 0' "$TEMP_ARRAY_FILE" > /dev/null 2>&1; then
        echo -e "${RED}❌ Tidak ada data burner wallet yang valid ditemukan untuk dibackup.${NC}"
        rm -f "$TEMP_ARRAY_FILE"
        read -p "Tekan Enter untuk kembali ke menu utama..."
        return 1
    fi

    jq . "$TEMP_ARRAY_FILE" > "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 BACKUP SELESAI!${NC}"
        echo -e "Semua data burner wallet tersimpan di: ${CYAN}$BACKUP_FILE${NC}"
        echo -e "${RED}⚠️ SIMPAN FILE INI DI TEMPAT AMAN! (Berisi Kunci Privat)${NC}"
        echo ""
    else
        echo -e "${RED}❌ GAGAL: Terjadi kesalahan saat memformat atau menyimpan file backup.${NC}"
    fi

    rm -f "$TEMP_ARRAY_FILE"
    read -p "Tekan Enter untuk kembali ke menu utama..."
}

while true; do
    show_header
    echo -e "${CYAN}        MENU OPERASI MAWARI GUARDIAN NODE ${NC}"
    echo -e "${BLUE}======================================================"
    echo -e "1. ${GREEN}Cek & Instalasi Docker & Tools (Wajib)${NC}"
    echo -e "2. ${YELLOW}Luncurkan Node Baru${NC}"
    echo -e "3. ${CYAN}Cek Log & Burner Wallet Node yang Sedang Berjalan${NC}"
    echo -e "4. ${BLUE}Jalankan Ulang Node yang Berhenti (Start)${NC}"
    echo -e "5. ${RED}Hentikan/Hapus Node yang Sedang Berjalan${NC}"
    echo -e "6. ${GREEN}Backup Semua Burner Wallet (WAJIB AMAN)${NC}"
    echo -e "7. ${RED}Keluar${NC}"
    echo -e "${BLUE}======================================================${NC}"

    read -p "Pilih opsi (1-7): " MAIN_CHOICE

    case $MAIN_CHOICE in
        1) check_and_install_requirements ;;
        2) run_new_nodes ;;
        3) check_running_nodes ;;
        4) restart_stopped_nodes ;; 
        5) stop_node ;;
        6) backup_all_burner_wallets ;;
        7) echo -e "${CYAN}Terima kasih. Sampai jumpa!${NC}"; break ;;
        *) echo -e "${RED}❌ ERROR: Pilihan tidak valid. Coba lagi.${NC}"
            read -p "Tekan Enter untuk kembali ke menu utama..." ;;
    esac
    echo ""
done
