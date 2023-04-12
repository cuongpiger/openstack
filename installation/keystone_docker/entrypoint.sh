rm -rf /osprofiler /requirements /keystone /devstack && \
apt-get update && \
apt-get install python3.8 python3.8-dev git -y && \
git clone --depth=1 https://github.com/cuongpiger/osprofiler --branch zed/dev /osprofiler && \
git clone --depth=1 https://opendev.org/openstack/requirements.git /requirements && \
git clone --depth=1 https://opendev.org/openstack/keystone.git /keystone && \
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install apache2 apache2-dev bc bsdmainutils curl g++ gawk gcc gettext git graphviz iputils-ping libapache2-mod-proxy-uwsgi libffi-dev libjpeg-dev libpcre3-dev libpq-dev libssl-dev libsystemd-dev libxml2-dev libxslt1-dev libyaml-dev lsof openssh-server openssl pkg-config psmisc python3-dev python3-pip python3-systemd python3-venv python3-testresources tar tcpdump unzip uuid-runtime wget zlib1g-dev iputils-arping libkrb5-dev libldap2-dev libsasl2-dev memcached python3-mysqldb sqlite3 pcp --assume-yes && \
python3 -m pip install -c /requirements/upper-constraints.txt -U os-testr PyMySQL && \
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install uwsgi uwsgi-plugin-python3 libapache2-mod-proxy-uwsgi --assume-yes && \
if ! grep -q "ServerName 127.0.0.1" /etc/apache2/apache2.conf; then 
    echo 'ServerName 127.0.0.1' >> /etc/apache2/apache2.conf
fi && \
a2enmod proxy && a2enmod proxy_uwsgi && a2enmod proxy_http && \
service apache2 restart && \
python3 -m pip install -c /requirements/upper-constraints.txt keystonemiddleware python-memcached jaeger-client python-openstackclient && \
python3 -m pip install -c /requirements/upper-constraints.txt /keystone && \
rm -rf /etc/keystone && mkdir /etc/keystone && \
install -d -o root /etc/keystone && install -m 600 /dev/null /etc/keystone/keystone.conf && \
echo "[identity]
password_hash_rounds = 4
driver = sql

[assignment]
driver = sql

[role]
driver = sql

[resource]
driver = sql

[cache]
memcache_servers = localhost:11211
backend = dogpile.cache.memcached
enabled = True

[oslo_messaging_notifications]
transport_url = rabbit://stackrabbit:secret@openstack-rabbitmq:5672/

[DEFAULT]
max_token_size = 16384
debug = True
logging_exception_prefix = ERROR %(name)s %(instance)s
logging_default_format_string = %(color)s%(levelname)s %(name)s [-%(color)s] %(instance)s%(color)s%(message)s
logging_context_format_string = %(color)s%(levelname)s %(name)s [%(global_request_id)s %(request_id)s %(project_name)s %(user_name)s%(color)s] %(instance)s%(color)s%(message)s
logging_debug_format_suffix = {{(pid=%(process)d) %(funcName)s %(pathname)s:%(lineno)d}}
public_endpoint = http://0.0.0.0/identity

[token]
expiration = 7200
provider = fernet

[database]
connection = mysql+pymysql://root:secret@openstack-mysql:3306/keystone?charset=utf8&plugin=dbcounter

[fernet_tokens]
key_repository = /etc/keystone/fernet-keys/

[credential]
key_repository = /etc/keystone/credential-keys/

[security_compliance]
unique_last_password_count = 2
lockout_duration = 10
lockout_failure_attempts = 2

[oslo_policy]
enforce_new_defaults = false
enforce_scope = false
policy_file = policy.yaml

[profiler]
connection_string = jaeger://openstack-jaeger:6381
hmac_keys = SECRET_KEY
trace_sqlalchemy = True
enabled = True " > /etc/keystone/keystone.conf && \
echo "d /var/run/uwsgi 0755 root root" > /etc/tmpfiles.d/uwsgi.conf && \
systemd-tmpfiles --create /etc/tmpfiles.d/uwsgi.conf && \
echo "[uwsgi]
chmod-socket = 666
socket = /var/run/uwsgi/keystone-wsgi-public.socket
lazy-apps = true
add-header = Connection: close
buffer-size = 65535
hook-master-start = unix_signal:15 gracefully_kill_them_all
thunder-lock = true
plugins = http,python3
enable-threads = true
worker-reload-mercy = 90
exit-on-reload = false
die-on-term = true
master = true
processes = 2
wsgi-file = /usr/local/bin/keystone-wsgi-public" > /etc/keystone/keystone-uwsgi-public.ini && \
echo 'ProxyPass "/identity" "unix:/var/run/uwsgi/keystone-wsgi-public.socket|uwsgi://uwsgi-uds-keystone-wsgi-public" retry=0' > /etc/apache2/sites-available/keystone-wsgi-public.conf && \
a2ensite keystone-wsgi-public && a2enmod proxy_http && service apache2 restart && \
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install libapache2-mod-wsgi-py3 --assume-yes && \
git clone --depth=1 https://github.com/openstack/devstack /devstack && \
python3 -m pip install -c /requirements/upper-constraints.txt /devstack/tools/dbcounter && \
keystone-manage --config-file /etc/keystone/keystone.conf db_sync && \
keystone-manage --config-file /etc/keystone/keystone.conf fernet_setup --keystone-user root --keystone-group root && \
echo "[Unit]
Description = Devstack devstack@keystone.service

[Service]
RestartForceExitStatus = 100
NotifyAccess = all
Restart = always
KillMode = process
Type = notify
ExecReload = /usr/bin/kill -HUP $MAINPID
ExecStart = /usr/bin/uwsgi --procname-prefix keystone --ini /etc/keystone/keystone-uwsgi-public.ini
User = root
SyslogIdentifier = devstack@keystone.service

[Install]
WantedBy = multi-user.target" > /etc/systemd/system/devstack@keystone.service && \
echo "FINISH"


keystone-manage bootstrap --bootstrap-username admin --bootstrap-password secret --bootstrap-project-name admin --bootstrap-role-name admin --bootstrap-service-name keystone --bootstrap-region-id RegionOne --bootstrap-public-url http://0.0.0.0/identity