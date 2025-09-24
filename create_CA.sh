#!/bin/bash

ORG="<org>"
CANAME="CA_${ORG}"
CITY="<city>"
LOCATION="<location>"
RETENTION_CA=3650
CA_DIR="${CANAME}"

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
