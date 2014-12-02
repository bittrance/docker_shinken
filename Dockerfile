# Shinken Docker installation using pip (latest)
FROM        debian:wheezy
MAINTAINER  Rohit Gupta

# Install Shinken, Nagios plugins, nginx and supervisord
RUN         apt-get update && apt-get install -y python-pip \
                python-pycurl \
                python-cherrypy3 \
                nagios-plugins \
                nginx \
                supervisor
RUN         useradd --create-home shinken && \
                pip install shinken && \
                update-rc.d -f shinken remove

# Install shinken modules from shinken.io
RUN         su - shinken -c 'shinken --init' && \
                su - shinken -c 'shinken install webui' && \
                su - shinken -c 'shinken install auth-htpasswd' && \
                su - shinken -c 'shinken install sqlitedb' && \
                su - shinken -c 'shinken install pickle-retention-file-scheduler' && \
                su - shinken -c 'shinken install booster-nrpe'

# Configure nginx
ADD         shinken/shinken_nginx.conf /etc/nginx/sites-available/shinken_nginx.conf
RUN         mkdir -p /var/log/nginx && \
                rm -f /etc/nginx/sites-enabled/default && \
                ln -sf /etc/nginx/sites-available/shinken_nginx.conf /etc/nginx/sites-enabled/shinken_nginx.conf && \
                update-rc.d -f nginx remove && \
                echo "daemon off;" >> /etc/nginx/nginx.conf

# Configure Shinken modules
ADD         shinken/shinken.cfg /etc/shinken/shinken.cfg
ADD         shinken/broker-master.cfg /etc/shinken/brokers/broker-master.cfg
ADD         shinken/poller-master.cfg /etc/shinken/pollers/poller-master.cfg
ADD         shinken/scheduler-master.cfg /etc/shinken/schedulers/scheduler-master.cfg
ADD         shinken/webui.cfg /etc/shinken/modules/webui.cfg
RUN         mkdir -p /etc/shinken/custom_configs
RUN         ln -sf /etc/shinken/custom_configs/htpasswd.users /etc/shinken/htpasswd.users

# Expose /var/log and shinken's custom_configs as mountable directories
VOLUME      ["/etc/shinken/custom_configs", "/var/log/"]

# configure supervisor
ADD         supervisor/conf.d/* /etc/supervisor/conf.d/

# Expost port 80 (nginx)
EXPOSE  80

# Default docker process
CMD ["supervisord", "-c", "/etc/supervisord.conf", "-n"]