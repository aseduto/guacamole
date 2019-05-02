# guacamole

A very basic guacamole single container server. 

Let you startup a guacamole server just editing one file.

To get start:

```bash
git clone https://github.com/aseduto/guacamole.git
cd guacamole
mkdir -p /storage/guacamole
cp ./guacamole.properties /storage/guacamole
cp ./user-mapping.xml /storage/guacamole
docker build --tag guacamole .
```
Use your favorite editor to add to /storage/guacamole/user-mapping.xml all the host you want to get access to.

Just start the container:

```bash
docker run -d --name guacamole -p 8080:8080 -v /storage/guacamole:/app/guacamole	 guacamole 
```

Connect to your guacamole server on port 8080.

To modify your connections just edit your /storage/guacamole/user-mapping.xml logoff and log back in to your guacamole server. 

## Security

The above configuration is not very secured since password will travel as clear test. Furthermore there is only a single password security.

This set up is well suited on protected environments like an intranet.

If you need your guacamole server on the internet better security should be applied.

A guacamole server on the internet can be very useful to work beyond a proxy for instance.

You can use the included docker-compose.yml file to startup the guacamole implementation beyond an envoy proxy that will implement tls mutual authentication for full security.

This means https and certificate client authentication.

In order to achieve this you need to have server and client certificates.

In both cases you can either use a Certificate Authority or you can generates your own.

If you decide to generate your own you can fallowing this directions:

1. Make a copy of the tls directory
2. Edit the files to reflect your information. At least you have to edit server.cert.request to reflect the dns and/or ip you will use to connect to your server.
3. Run this commands in your bash shell:

```bash

echo "Generate CA CERTS"

openssl genrsa -out ca.key.pem 2048
openssl req -new -key ca.key.pem -days 3650 -x509 -nodes -out ca.pem -outform PEM -config ca.cert.request


function cert {

CLIENTCERT=$1

if [ -e ${CLIENTCERT}.cert.request ]
then

openssl genrsa -out ${CLIENTCERT}.key.pem 2048
openssl req -new -key ${CLIENTCERT}.key.pem -out "${CLIENTCERT}.csr" -config ${CLIENTCERT}.cert.request
openssl x509 -req -in "${CLIENTCERT}.csr" -CA ca.pem -CAkey ca.key.pem -CAcreateserial -out "${CLIENTCERT}.pem" -days 10000 -extensions v3_ext -extfile ${CLIENTCERT}.cert.request
openssl x509 -noout -fingerprint -sha256 -inform pem -in "${CLIENTCERT}.pem"

else
    echo "missing ${CLIENTCERT}.cert.request file"
fi

}

echo "Generate Server Cert"

cert "server"

echo "Generate Client Cert"

cert "client"

openssl pkcs12 -in client.pem -inkey client.key.pem -export -out merged.pfx

```

4. Now put safely away your ca.kye.pem. 
5. On any machine you want to connect to your guacamole server trust ca.pem
6. Copy server.key.pem server.pem ca.pem to your guacamole server in /storage/tls
7. Copy envoy.yaml to /storage/envoy
```bash
mkdir -p /storage/envoy
cp envoy.yaml /storage/envoy
```
8. run ```docker-compose -d up```










