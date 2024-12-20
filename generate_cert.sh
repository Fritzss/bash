ORG=org
CANAME=CA_$ORG
CITY=town
LOCATION=local
MYCERT=<asd>.$LOCATION.$ORG
# 3650 days = 10 years
RETENTION_CA=3650
RETENTION=3650
# optional
mkdir $CANAME
cd $CANAME
# generate aes encrypted private key
openssl genrsa -aes256 -out $CANAME.key 4096

# create CA certificate, 3650 days = 10 years
# the following will ask for common name, country, ...
openssl req -x509 -new -nodes -key $CANAME.key -sha256 -days $RETENTION_CA -out $CANAME.crt
# ... or you provide common name, country etc. via:
openssl req -x509 -new -nodes -key $CANAME.key -sha256 -days $RETENTION_CA -out $CANAME.crt -subj "/CN=$LOCATION CA/C=AT/ST=$CITY/L=$LOCATION/O=$ORG"

# add CA trusted store
cp $CANAME.crt /usr/local/share/ca-certificates
update-ca-certificates

# create CSR
openssl req -new -nodes -out $MYCERT.csr -newkey rsa:4096 -keyout $MYCERT.key -subj "/CN=$MYCERT/C=AT/ST=$CITY/L=$LOCATION/O=$ORG"
# create a v3 ext file for SAN properties
cat > $MYCERT.v3.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = <asd>.$LOCATION.$ORG
DNS.2 = <qwe>.$LOCATION.$ORG
DNS.3 = <zxc>.$LOCATION.$ORG
IP.1 = <ipaddr>
EOF

#sign crt
openssl x509 -req -in $MYCERT.csr -CA $CANAME.crt -CAkey $CANAME.key -CAcreateserial -out $MYCERT.crt -days 730 -sha256 -extfile $MYCERT.v3.ext
# remove password from private key
openssl rsa -in $MYCERT.key -out $MYCERT.key
#check 
openssl x509 -in $MYCERT.crt -text | grep -i dns
