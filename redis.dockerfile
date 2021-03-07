FROM redis:alpine

MAINTAINER Pawlrus

ARG USER="sshuser"
#create ssh user
RUN adduser -D ${USER}
#fix disabled user issue
RUN sed -i s/sshuser:!/"sshuser:*"/g /etc/shadow

#always update
RUN apk update

#add ssh
RUN apk add --no-cache openssh openssh-server openrc supervisor


#ssh's chroot dir
RUN mkdir /ch

#setup ssh, lock it down and make host keys... and not in that order
#RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
#RUN ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
#RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
#RUN echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
#RUN echo "KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256" >> /etc/ssh/sshd_config
#RUN echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes128-ctr" >> /etc/ssh/sshd_config
#RUN echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com" >> /etc/ssh/sshd_config
#RUN echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
#RUN echo "Match User sshuser" >> /etc/ssh/sshd_config
#RUN echo "    PermitTTY no" >> /etc/ssh/sshd_config
#RUN echo "    ForceCommand /sbin/nologin" >> /etc/ssh/sshd_config
#RUN echo "    ChrootDirectory /ch" >> /etc/ssh/sshd_config
#RUN echo "Match all" >> /etc/ssh/sshd_config
#RUN sed -i s/"AllowTcpForwarding no"/"AllowTcpForwarding yes"/g /etc/ssh/sshd_config

#RUN mkdir /home/${USER}/.ssh
#RUN chmod 700 /home/${USER}/.ssh
#RUN chown ${USER}:${USER} /home/${USER}/.ssh
#COPY web.key.pub /home/${USER}/.ssh
#COPY fido2.key.pub /home/${USER}/.ssh

#RUN cat /home/${USER}/.ssh/web.key.pub >> /home/${USER}/.ssh/authorized_keys
#RUN cat /home/${USER}/.ssh/fido2.key.pub >> /home/${USER}/.ssh/authorized_keys
#RUN chmod 600 /home/${USER}/.ssh/authorized_keys
#RUN chown ${USER}:${USER} /home/${USER}/.ssh/authorized_keys

#RUN rc-update add sshd
#RUN /etc/init.d/sshd start
#CMD ["/usr/sbin/sshd"]
#CMD ["/usr/sbin/sshd", "-D", "-e"]
#RUN /usr/sbin/sshd &

#redis config, bind to localhost only since usig ssh forwarding
COPY tests/tls tls
RUN mkdir /etc/redis
#RUN echo "bind localhost" > /etc/redis/redis.conf
#RUN echo "cipher_suites ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384" >> /etc/redis/redis.conf
RUN echo "tls-ciphers HIGH:!MEDIUM:!LOW:!EXP:!eNULL:!aNULL:!3DES:!DES:!RC4:!RC2:!MD5:!SHA1" >> /etc/redis/redis.conf
RUN echo "tls-protocols 'TLSv1.2 TLSv1.3'" >> /etc/redis/redis.conf
RUN echo "tls-cert-file /data/tls/redis.crt" >> /etc/redis/redis.conf
RUN echo "tls-key-file /data/tls/redis.key" >> /etc/redis/redis.conf
RUN echo "tls-ca-cert-file /data/tls/ca.crt" >> /etc/redis/redis.conf
RUN echo "tls-dh-params-file /data/tls/redis.dh" >> /etc/redis/redis.conf
#CMD ["redis-cli", "config", "set", "bind", "localhost"]

#COPY gen-redis-crts.sh gen-redis-crts.sh
#RUN sh -c gen-redis-crts.sh

#jankey method for running multiple services at init......
#RUN redis-server /etc/redis/redis.conf
#VOLUME ["/sys/fs/cgroup" ]
#COPY sshd.sh sshd.sh
#RUN chmod +x sshd.sh
#COPY proc.sh proc.sh
#CMD sh ./proc.sh

#COPY supervisord.conf /etc/supervisord.conf
#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
CMD redis-server /etc/redis/redis.conf
#ENTRYPOINT sh ./sshd.sh
#ENTRYPOINT ["sh","-c", "rc-status; rc-service sshd start"]
#ENTRYPOINT redis-server /etc/redis/redis.conf && /usr/sbin/sshd -D -e
#ENTRYPOINT /usr/sbin/sshd -D -e
#ENTRYPOINT ["sh","-c", "/usr/sbin/sshd", "-D", "-e"]
#RUN redis-cli config set bind localhost
#127.0.0.1
