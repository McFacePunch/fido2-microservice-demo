# python-FIDO2 Demo dockerized as a microservice

This project makes use of the yubico python-fido2 library and its demo along
with some customizations to enable use of docker, apache and redis to create
a POC microservice.

### Design

This POC consists of 3 containers currently, fido2 webserver, redis session
store, and a 2nd webserver to simulate an application that requires webauth
to access.

The "fido2" server uses apache and wsgi to host the webauth demo and provide 
webauth with hardware token integration. Modifications have been made to the 
base demo so it can then provide a session backed by a redis session store.
The session store allows anyone who has completed webauth to then access a 
webserver hosted on another docker instance which is also tied into the redis
session store.

By using a combination of redis and webauth one can build a secure and highly
distributed authentication service suitable for both micro and monolithic 
services, especially in cloud environments.

#### Caveats 

- Currently, attestation is not fully implemented in the demo. This is not ideal 
for production environments and can somewhat easily be enabled but makes the demo
  more complicated than desired.
  
- 

### Runing containers

There is a makefile provided to automate some of the work like cleaning of .pyc 
files and other build/hygine needs.

```
make clean && make build
make test
```

To run build the containers there are two options, first it can be done with the
`run.sh` script which automatically deletes old files before begining, or second
it can be done mannually by running the `cert-gen.sh` script to produce needed
TLS certs for webservers and then running `docker-compose up`