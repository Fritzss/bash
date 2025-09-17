#!/bin/bash

# Конфигурационные параметры
ORG="org"
CANAME="CA_${ORG}"
CITY="town"
LOCATION="local"
MYCERT="<asd>.${LOCATION}.${ORG}"
RETENTION_CA=3650   # 10 лет для CA
RETENTION=3650      # 10 лет для сертификатов
CA_DIR="${CANAME}"  # Директория для файлов CA

# Создание директории для CA
mkdir -p "${CA_DIR}" 
cd "${CA_DIR}" 

# Генерация ключа CA с шифрованием AES-256
echo "Генерация ключа Центра Сертификации..."
openssl genrsa -aes256 -out "${CANAME}.key" 4096

# Создание самоподписанного сертификата CA
echo "Создание сертификата Центра Сертификации..."
openssl req -x509 -new -nodes \
    -key "${CANAME}.key" \
    -sha256 \
    -days "${RETENTION_CA}" \
    -out "${CANAME}.crt" \
    -subj "/CN=${LOCATION} CA/C=AT/ST=${CITY}/L=${LOCATION}/O=${ORG}" \
    -passin pass:<ca password>

# Добавление CA в доверенные сертификаты системы
echo "Добавление CA в системное хранилище..."
sudo cp "${CANAME}.crt" /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Генерация приватного ключа для сертификата
echo "Создание ключа сертификата..."
openssl req -new -nodes \
    -out "${MYCERT}.csr" \
    -newkey rsa:4096 \
    -keyout "${MYCERT}.key" \
    -subj "/CN=${MYCERT}/C=AT/ST=${CITY}/L=${LOCATION}/O=${ORG}" \
    -passin pass:<crt pass>

# Создание конфигурационного файла расширений (SAN)
echo "Генерация конфигурации SAN..."
cat > "${MYCERT}.v3.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment
subjectAltName=@alt_names

[alt_names]
DNS.1=${MYCERT}
DNS.2=<qwe>.${LOCATION}.${ORG}
DNS.3=<zxc>.${LOCATION}.${ORG}
IP.1=<ipaddr>
EOF

# Подпись сертификата CA
echo "Подпись сертификата..."
openssl x509 -req \
    -in "${MYCERT}.csr" \
    -CA "${CANAME}.crt" \
    -CAkey "${CANAME}.key" \
    -CAcreateserial \
    -out "${MYCERT}.crt" \
    -days "${RETENTION}" \
    -sha256 \
    -extfile "${MYCERT}.v3.ext"
    -passin pass:<ca pass>

# Удаление пароля из приватного ключа
echo "Удаление пароля из ключа..."
openssl rsa -in "${MYCERT}.key" \
    -out "${MYCERT}.key" \
    -pass: pass:<crt pass>

# all chains
cat "${CANAME}.crt" >> "${MYCERT}.crt"
# Проверка DNS-записей в сертификате
echo "Проверка DNS-записей:"
openssl x509 -in "${MYCERT}.crt" -noout -text | grep -i DNS

echo "Готово! Сертификаты находятся в директории: ${CA_DIR}"
