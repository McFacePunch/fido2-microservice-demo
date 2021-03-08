#delete old certs
rm -rf company.se*

#gen new key + csr
#openssl \
#    req \
#    -nodes \
#    -newkey rsa:4096 \
#    -keyout company.se.key \
#    -out company.se.csr \
#    -subj "/C=SE/ST=Stockholm Lan/L=Stockholm/O=Company AB/OU=DevOps/CN=www.company.se/emailAddress=dev@www.company.se"

#linux version
#openssl req \
#  -newkey rsa:4096 \
#  -x509 \
#  -new \
#  -nodes \
#  -keyout company.se.key \
#  -out company.se.crt  \
#  -subj "/C=SE/ST=Stockholm Lan/L=Stockholm/O=Company AB/OU=DevOps/CN=www.company.se/emailAddress=dev@www.company.se" \
#  -sha256  \
#  -days 365  \
#  -addext "subjectAltName = DNS:company.se,IP:127.0.0.1,IP:192.168.1.1" \
#  -addext "extendedKeyUsage = serverAuth"

#macos versions
#fido2 and web server certs
openssl req \
  -newkey rsa:4096 \
  -x509 \
  -nodes \
  -keyout company.se.key \
  -new \
  -out company.se.crt \
  -subj "/C=SE/ST=Stockholm Lan/L=Stockholm/O=Company AB/OU=DevOps/CN=security-engineer.test/emailAddress=dev@security-engineer.test" \
  -extensions v3_new \
  -config <(cat /System/Library/OpenSSL/openssl.cnf \
  <(printf '[v3_new]\nsubjectAltName=DNS:security-engineer.test,IP:127.0.0.1,IP:192.168.1.1\nextendedKeyUsage=serverAuth')) \
  -sha256 \
  -days 365

#redis certs
#openssl req \
#  -newkey rsa:4096 \
#  -x509 \
#  -nodes \
#  -keyout redis.company.se.key \
#  -new \
#  -out redis.company.se.crt \
#  -subj "/C=SE/ST=Stockholm Lan/L=Stockholm/O=Company AB/OU=DevOps/CN=www.company.se/emailAddress=dev@www.company.se" \
#  -extensions v3_new \
#  -config <(cat /System/Library/OpenSSL/openssl.cnf \
#  <(printf '[v3_new]\nsubjectAltName=DNS:redis.company.se,DNS:redis,IP:127.0.0.1,IP:192.168.1.1\nextendedKeyUsage=serverAuth')) \
#  -sha256 \
#  -days 365

#redis port forward ssh keys
#ssh-keygen -b 4096 -t rsa -f ./fido2.key -q -N ""
#ssh-keygen -b 4096 -t rsa -f ./web.key -q -N ""

#generate redis certs
bash gen-redis-crts.sh

#make cert
#openssl x509 -req -days 365 -in company.se.csr -signkey company.se.key -out company.se.crt

#remove CSR, not needed anymore
#rm ./company.se.csr