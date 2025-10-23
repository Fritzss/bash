#!/bin/bash
CONFIG_FILE="./config_crt.cfg"

if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "Configuration loaded from $CONFIG_FILE"
else
        echo "Error: Configuration file $CONFIG_FILE not found."
        exit 1
fi

if [ -s "./${CA_DIR}" ] ; then
   ls "./${CA_DIR}"
else 
  mkdir -p "${CA_DIR}"
  cd "${CA_DIR}"
  pwd

if [ -s ./.pass ] ; then
   PASS=$(cat ./.pass)
else
   tr -dc 'A-Za-z0-9!@$%^*)' < /dev/urandom | head -c 25 > .pass
   PASS=$(cat ./.pass)
fi

if [ -s ./"${CANAME}.key" ] ; then
  ls ./"${CANAME}.key"
else
echo "Генерация ключа Центра Сертификации..."
openssl genrsa -aes256 -out "${CANAME}.key" -passout pass:$PASS 4096
fi


if [ -s ./"${CANAME}.crt" ] ; then
   openssl x509 -in "${CANAME}.crt" -text
else
echo "Создание сертификата Центра Сертификации..."
openssl req -x509 -new -nodes \
    -key "${CANAME}.key" \
    -sha256 \
    -days "${RETENTION_CA}" \
    -out "${CANAME}.crt" \
    -subj "/CN=${LOCATION} CA/C=AT/ST=${CITY}/L=${LOCATION}/O=${ORG}" \
    -passin pass:$PASS
fi

sudo cp "${CANAME}.crt" /usr/local/share/ca-certificates/
sudo update-ca-certificates
fi
