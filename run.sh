#!/usr/bin/env bash

echo making new certs
bash cert-gen.sh

echo killing old containers
docker-compose rm -fs

echo building new containers
docker-compose up --build -d

echo done