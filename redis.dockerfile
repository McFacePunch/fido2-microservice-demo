FROM redis:alpine

MAINTAINER Pawlrus

#always update
RUN apk update

#add ssh
RUN apk add --no-cache openssh

#setup ssh, lock it down and send pub keys
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
RUN ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
RUN echo "KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256" >> /etc/ssh/sshd_config
RUN echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes128-ctr" >> /etc/ssh/sshd_config
RUN echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com" >> /etc/ssh/sshd_config
#RUN echo "Match User redis proxy-only" >> /etc/ssh/sshd_config
#RUN echo "    PermitTTY no" >> /etc/ssh/sshd_config
#RUN echo "    ForceCommand /sbin/nologin" >> /etc/ssh/sshd_config
#RUN echo "    ChrootDirectory %h" >> /etc/ssh/sshd_config
#RUN echo "Match all" >> /etc/ssh/sshd_config
RUN mkdir /home/redis/.ssh
COPY web.key.pub /home/redis/.ssh
COPY fido2.key.pub /home/redis/.ssh
RUN cat /home/redis/.ssh/fido2.key.pub >> /home/redis/.ssh/authorized_keys
RUN cat /home/redis/.ssh/fido2.key.pub >> /home/redis/.ssh/authorized_keys
RUN /usr/sbin/sshd &

#redis config, bind to localhost only since usig ssh forwarding
RUN mkdir /etc/redis/
RUN echo "bind localhost" /etc/redis/redis.conf
#RUN redis-cli config set bind localhost
#127.0.0.1
