FROM debian:latest

MAINTAINER Pawlrus

ARG APP_NAME=FIDO2-Example
ENV APP_NAME=${APP_NAME}

ARG USER_ID="10001"
ARG GROUP_ID="srv"
ARG HOME="/srv"

ENV HOME=${HOME}
RUN groupadd --gid ${USER_ID} ${GROUP_ID} && \
    useradd --create-home --uid ${USER_ID} --gid ${GROUP_ID} --home-dir /srv ${GROUP_ID}

# List packages here
RUN apt-get update && apt-get install -y apache2 \
    libapache2-mod-wsgi-py3 \
    python3 \
    python-dev\
    python3-pip \
    ssh &&\
    apt-get autoremove -y && apt-get clean

# Upgrade pip3
RUN pip3 install --upgrade pip

#WORKDIR ${HOME}

#install python requirements
ADD requirements requirements/
RUN pip3 install -r requirements/requirements.txt

#setup apache2 mods
RUN a2enmod wsgi
RUN a2enmod headers
RUN a2enmod ssl
#RUN a2enmod auth_digest

# Copy over the apache configuration file and enable the site
COPY ./apache-flask.conf /etc/apache2/sites-available/apache-flask.conf
RUN a2ensite apache-flask

# Copy over the wsgi files
COPY ./apache-flask.wsgi /var/www/apache-flask/apache-flask.wsgi

COPY ./modserver.py /var/www/apache-flask/srv/
COPY ./__init__.py /var/www/apache-flask/srv/
COPY ./${HOME} /var/www/apache-flask/srv/

#copy over certs
COPY ./company.se.crt /etc/apache2/ssl/company.se.crt
COPY ./company.se.key /etc/apache2/ssl/company.se.key

RUN a2dissite 000-default.conf
RUN a2ensite apache-flask.conf

#RUN ssh forwarding of local port to remote port
COPY fido2.key /home/
RUN chmod 600 /home/fido2.key
RUN chown srv:srv /home/fido2.key
RUN ssh -oStrictHostKeyChecking=no -L 6379:127.0.0.1:6379 sshuser@redis -i /home/fido2.key &

EXPOSE 443

# Drop root and change ownership of the application folder to the application user
RUN chown -R ${USER_ID}:${GROUP_ID} ${HOME}
RUN chown -R ${USER_ID}:${GROUP_ID} /var/log/apache2
RUN chown -R ${USER_ID}:${GROUP_ID} /var/log/apache2/error.log
RUN chown -R ${USER_ID}:${GROUP_ID} /var/log/apache2/access.log
#setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/apache2 #possible fix
#USER ${USER_ID} #causing apache2ctl -D FOREGROUND to fail???

WORKDIR /var/www/apache-flask

CMD  /usr/sbin/apache2ctl -D FOREGROUND

#ENTRYPOINT ["python", "/srv/fido2.py"]
