# python-FIDO2 Demo dockerized as a microservice

This project makes use of the yubico python-fido2 library and its demo along
with some customizations to enable use of docker, apache and redis together 
in a POC microservice.

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
  
### Secutiy

- Currently the containers make use of customer certs, a proper CA and signing would be a good improvement.

- The containers all make use of TLS with a restrictive cipher set that leans towards compatibility.

- For deployment and testing I would suggest also adding Anchor, BlackDuck or similar static analysis tooling for
  detection of known CVEs as they come up to make sure between builds the container is getting checked.
  
- Each system and its service logs to stderr currently but for production that should be changed to syslog or similar
  and the org's log servers should be configured to make sure they dont just sit in the container
  
- when updating sources, especially dealing with the web applications and chaning their interfaces there should
  be an additional revivew of how that might impact things. For example if adding new login handling it shoudle be 
  evaluated to not cause a bypass for other methods.

### Getting Started

First clone the project

```
git clone --recursive git@github.com:McFacePunch/fido2-microservice-demo.git
```

The git submodule is not needed in its entirety, so for simplicity I suggest 
using a link to bring the files needed up to the root of the project.

```
cd fido2-microservice-demo
ln -s ./python-fido2/examples/server ./srv
```

### Runing containers

To run build the containers there are two options, first it can be done with the
`run.sh` script which automatically deletes old files before begining, or second
it can be done mannually by running the `cert-gen.sh` script to produce needed
TLS certs for webservers and then running `docker-compose up`
```
bash cert-gen.sh
docker-compose up
```
