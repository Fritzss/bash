#!/bin/bash

CONFIG_FILE="./config_crt.cfg"

if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "Configuration loaded from $CONFIG_FILE"
else
        echo "Error: Configuration file $CONFIG_FILE not found."
        exit 1
fi

mkdir -p "./${MYCERT}"

PASSCA=$(cat "./${CANAME}/.pass")

echo $PASSCA

cd "./${MYCERT}"

if [ -s ./.pass ] ; then
   PASS=$(cat ./.pass)
else
   tr -dc 'A-Za-z0-9!@$%^*)' < /dev/urandom | head -c 25 > .pass
   PASS=$(cat ./.pass)
fi

# func generate alt_names

generate_alt_names_simple() {
    local dns_count=0
    local ip_count=0

    # Собираем DNS записи
    for i in {1..10}; do
        var_name="DNS${i}"
        if [[ -n "${!var_name}" ]]; then
            ((dns_count++))
            echo "DNS.${dns_count}=${!var_name}"
        fi
    done

    # Собираем IP записи
    for i in {1..10}; do
        var_name="IP${i}"
        if [[ -n "${!var_name}" ]]; then
            ((ip_count++))
            echo "IP.${ip_count}=${!var_name}"
        fi
    done
}

# Создание конфигурационного файла расширений (SAN)
echo "Генерация конфигурации SAN..."
cat > "${MYCERT}.v3.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment
subjectAltName=@alt_names

[alt_names]
$(generate_alt_names_simple)
EOF


# Генерация приватного ключа для сертификата
echo "Создание ключа сертификата..."
openssl req -new -nodes \
    -out "${MYCERT}.csr" \
    -newkey rsa:4096 \
    -keyout "${MYCERT}.key" \
    -subj "/CN=${MYCERT}/C=AT/ST=${CITY}/L=${LOCATION}/O=${ORG}" \
    -passin pass:$PASS


# Подпись сертификата CA
echo "Подпись сертификата..."
openssl x509 -req \
    -in "${MYCERT}.csr" \
    -CA "../${CANAME}/${CANAME}.crt" \
    -CAkey "../${CANAME}/${CANAME}.key" \
    -CAcreateserial \
    -out "${MYCERT}.crt" \
    -days "${RETENTION}" \
    -sha256 \
    -extfile "${MYCERT}.v3.ext" \
    -passin pass:$PASSCA

# Удаление пароля из приватного ключа
echo "Удаление пароля из ключа..."
openssl rsa -in "${MYCERT}.key" \
    -out "${MYCERT}.key" \
    -passin pass:$PASS

# all chains
cat "../${CANAME}/${CANAME}.crt" >> "${MYCERT}.crt"
# Проверка DNS-записей в сертификате
echo "Проверка DNS-записей:"
openssl x509 -in "${MYCERT}.crt" -noout -text | grep -i DNS

echo "Готово! Сертификаты находятся в директории: ${MYCERT}"
