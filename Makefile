## https://gist.github.com/Koronen/7361726
OPENSSL?=openssl

.PHONY: clean

default: ca.crt client.crt server.crt

%.key:
	$(OPENSSL) genrsa -out $@ 2048

ca.crt: ca.key
	$(OPENSSL) req -new -x509 -days 365 -key $< -out $@ -subj "/C=SE/L=Stockholm/O=Koronen/CN=localhost-ca"

server.req: server.key
	$(OPENSSL) req -new -key $< -out $@ -subj "/C=SE/L=Stockholm/O=Koronen/CN=localhost-server"

client.req: client.key
	$(OPENSSL) req -new -key $< -out $@ -subj "/C=SE/L=Stockholm/O=Koronen/CN=localhost-client"

%.crt: %.req ca.crt ca.key
	$(OPENSSL) x509 -req -days 365 -in $< -CA ca.crt -CAkey ca.key -set_serial 01 -out $@

clean:
rm -f *.crt *.key *.pem
