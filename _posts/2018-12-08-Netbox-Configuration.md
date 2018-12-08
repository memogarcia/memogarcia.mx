---
title: "Netbox Configuration"
date: 2018-12-08 15:44:21.980668 +0100
---

## VM configuration

Our current Netbox setup on BDMZ is deployed with the following configuration:

- 10.117.222.110
- 2 vCpus
- 4 GB RAM
- 50 GB data disk
- RHEL 7.5

## Python configuration

### Installing python3.6 from Red Hat software collections

    sudo yum install -y --nogpgcheck rh-python36 rh-python36-scldevel python36-setuptools
    sudo yum install -y --nogpgcheck python36-devel openldap-devel
    sudo scl enable rh-python36 bash

### Creating a python3.6 virtualenv

    python3.6 -m venv /opt/netbox/.netbox_venv
    source /opt/netbox/.netbox_venv/bin/activate

### Configure pip to use artifacts.kpn.org

    vim ~/.pip/pip.conf

```conf
[global]
index-url = <https://artifacts.kpn.org:65000/api/pypi/pypi/simple>
cert = /etc/pki/ca-trust/source/anchors/kpn_private_root_ca.crt

[search]
index-url = <https://artifacts.kpn.org/api/pypi/pypi>
```

## Database configuration

### Installing postgres9.6 from Red Hat software collections

    sudo yum install -y --nogpgcheck rh-postgresql96-postgresql rh-postgresql96-postgresql-server rh-postgresql96-postgresql-devel rh-postgresql96-postgresql-syspaths rh-python36-python-psycopg2
    sudo scl enable rh-postgresql96 bash
    sudo postgresql-setup --initdb
    sudo systemctl start rh-postgresql96-postgresql

### Creating netbox's database and user

    sudo -u postgres psql
    > CREATE USER netbox WITH PASSWORD 'redacted';
    > CREATE DATABASE netbox;
    > GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;
    > \q

### Database backup

    sudo mkdir /data/netbox_backup
    sudo chown -R postgres:postgres /data/netbox_backup
    sudo -u postgres pg_dump netbox > /tmp/"$( date '+%Y-%m-%d_%H-%M' )_postgres.db"
    sudo mv /tmp/"$( date '+%Y-%m-%d_%H-%M' )_postgres.db" /data/netbox_backup/"$( date '+%Y-%m-%d_%H-%M' )_postgres.db"
    rm /tmp/"$( date '+%Y-%m-%d_%H-%M' )_postgres.db"

### Database restore

    sudo -u postgres -f /data/netbox_backup/"$( date '+%Y-%m-%d_%H-%M' )_postgres.db"

TODO: ship the backup to an external location

## Netbox source code

Netbox is deployed with the version [v2.4.8 - 2018-11-20](<https://github.com/digitalocean/netbox/releases/tag/v2.4.8>) on `/opt/netbox/`

## Netbox bootstraping

    pip install -r /opt/netbox/netbox/netbox-2.4.8/netbox/requirements.txt

and the following extra python dependencies are required:

- django-rq
- django-auth-ldap
- python-slugify
- tqdm
- xlrd
- dnspython
- pynetbox
- gunicorn
- flask

and redis server:

    sudo yum install -y --nogpgcheck redis

then:

    vim /opt/netbox/netbox-2.4.8/netbox/netbox/configuration.py

```python
#########################
#                       #
#   Required settings   #
#                       #
#########################

# This is a list of valid fully-qualified domain names (FQDNs) for the NetBox server. NetBox will not permit write
# access to the server via any other hostnames. The first FQDN in the list will be treated as the preferred name.
#
# Example: ALLOWED_HOSTS = ['netbox.example.com', 'netbox.internal.local']
ALLOWED_HOSTS = ["*"]

# PostgreSQL database configuration.
DATABASE = {
'NAME': 'netbox',         # Database name
'USER': 'netbox',               # PostgreSQL username
'PASSWORD': 'redacted',           # PostgreSQL password
'HOST': 'localhost',      # Database server
'PORT': '',               # Database port (leave blank for default)
}

# This key is used for secure generation of random numbers and strings. It must never be exposed outside of this file.
# For optimal security, SECRET_KEY should be at least 50 characters in length and contain a mix of letters, numbers, and
# symbols. NetBox will not run without this defined. For more information, see
# <https://docs.djangoproject.com/en/dev/ref/settings/#std:setting-SECRET_KEY>
SECRET_KEY = 'redacted'


#########################
#                       #
#   Optional settings   #
#                       #
#########################

# Specify one or more name and email address tuples representing NetBox administrators. These people will be notified of
# application errors (assuming correct email settings are provided).
ADMINS = [
# ['John Doe', '[jdoe@example.com](mailto:jdoe@example.com)'],
]

# Optionally display a persistent banner at the top and/or bottom of every page. HTML is allowed. To display the same
# content in both banners, define BANNER_TOP and set BANNER_BOTTOM = BANNER_TOP.
BANNER_TOP = ''
BANNER_BOTTOM = ''

# Text to include on the login page above the login form. HTML is allowed.
BANNER_LOGIN = ''

# Base URL path if accessing NetBox within a directory. For example, if installed at <http://example.com/netbox/>, set:
# BASE_PATH = 'netbox/'
BASE_PATH = ''

# Maximum number of days to retain logged changes. Set to 0 to retain changes indefinitely. (Default: 90)
CHANGELOG_RETENTION = 90

# API Cross-Origin Resource Sharing (CORS) settings. If CORS_ORIGIN_ALLOW_ALL is set to True, all origins will be
# allowed. Otherwise, define a list of allowed origins using either CORS_ORIGIN_WHITELIST or
# CORS_ORIGIN_REGEX_WHITELIST. For more information, see <https://github.com/ottoyiu/django-cors-headers>
CORS_ORIGIN_ALLOW_ALL = False
CORS_ORIGIN_WHITELIST = [
# 'hostname.example.com',
]
CORS_ORIGIN_REGEX_WHITELIST = [
# r'^(https?://)?(\w+\.)?example\.com$',
]

# Set to True to enable server debugging. WARNING: Debugging introduces a substantial performance penalty and may reveal
# sensitive information about your installation. Only enable debugging while performing testing. Never enable debugging
# on a production system.
DEBUG = False

# Email settings
EMAIL = {
'SERVER': 'localhost',
'PORT': 25,
'USERNAME': '',
'PASSWORD': '',
'TIMEOUT': 10,  # seconds
'FROM_EMAIL': '',
}

# Enforcement of unique IP space can be toggled on a per-VRF basis. To enforce unique IP space within the global table
# (all prefixes and IP addresses not assigned to a VRF), set ENFORCE_GLOBAL_UNIQUE to True.
ENFORCE_GLOBAL_UNIQUE = False

# Enable custom logging. Please see the Django documentation for detailed guidance on configuring custom logs:
#   <https://docs.djangoproject.com/en/1.11/topics/logging/>
LOGGING = {}
# Setting this to True will permit only authenticated users to access any part of NetBox. By default, anonymous users
# are permitted to access most data in NetBox (excluding secrets) but not make any changes.
LOGIN_REQUIRED = True

# Setting this to True will display a "maintenance mode" banner at the top of every page.
MAINTENANCE_MODE = False

# An API consumer can request an arbitrary number of objects =by appending the "limit" parameter to the URL (e.g.
# "?limit=1000"). This setting defines the maximum limit. Setting it to 0 or None will allow an API consumer to request
# all objects by specifying "?limit=0".
MAX_PAGE_SIZE = 1000

# The file path where uploaded media such as image attachments are stored. A trailing slash is not needed. Note that
# the default value of this setting is derived from the installed location.
# MEDIA_ROOT = '/opt/netbox/netbox/media'

# Credentials that NetBox will uses to authenticate to devices when connecting via NAPALM.
NAPALM_USERNAME = ''
NAPALM_PASSWORD = ''

# NAPALM timeout (in seconds). (Default: 30)
NAPALM_TIMEOUT = 30

# NAPALM optional arguments (see <http://napalm.readthedocs.io/en/latest/support/#optional-arguments>). Arguments must
# be provided as a dictionary.
NAPALM_ARGS = {}

# Determine how many objects to display per page within a list. (Default: 50)
PAGINATE_COUNT = 255

# When determining the primary IP address for a device, IPv6 is preferred over IPv4 by default. Set this to True to
# prefer IPv4 instead.
PREFER_IPV4 = False

# The Webhook event backend is disabled by default. Set this to True to enable it. Note that this requires a Redis
# database be configured and accessible by NetBox (see `REDIS` below).
WEBHOOKS_ENABLED = True

# Redis database settings (optional). A Redis database is required only if the webhooks backend is enabled.
REDIS = {
'HOST': 'localhost',
'PORT': 6379,
'PASSWORD': '',
'DATABASE': 0,
'DEFAULT_TIMEOUT': 300,
}

# The file path where custom reports will be stored. A trailing slash is not needed. Note that the default value of
# this setting is derived from the installed location.
# REPORTS_ROOT = '/opt/netbox/netbox/reports'

# Time zone (default: UTC)
TIME_ZONE = 'UTC'

# Date/time formatting. See the following link for supported formats:
# <https://docs.djangoproject.com/en/dev/ref/templates/builtins/#date>
DATE_FORMAT = 'N j, Y'
SHORT_DATE_FORMAT = 'Y-m-d'
TIME_FORMAT = 'g:i a'
SHORT_TIME_FORMAT = 'H:i:s'
DATETIME_FORMAT = 'N j, Y g:i a'
SHORT_DATETIME_FORMAT = 'Y-m-d H:i'
```

then, apply the django database configuration:

    cd /opt/netbox/netbox-2.4.8/netbox
    python manage.py migrate

create the super user account:

    python manage.py createsuperuser
    > Username: root
    > Email address: [guillermo.ramirezgarcia@kpn.com](mailto:guillermo.ramirezgarcia@kpn.com)
    > Password:
    > Password (again):
    > Superuser created successfully.

and, load static files:

    python manage.py collectstatic --no-input

## Web server configuration

### Configure nginx

    sudo yum install -y --nogpgcheck nginx

    vim /etc/nginx/conf.d/netbox.conf

```conf
server {
listen 80;

server_name netbox.kpn.com;

client_max_body_size 25m;

location /static/ {
alias /opt/netbox/netbox/static/;
}

location / {
proxy_pass <http://127.0.0.1:8001>;
proxy_set_header X-Forwarded-Host $server_name;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-Proto $scheme;
add_header P3P 'CP="ALL DSP COR PSAa PSDa OUR NOR ONL UNI COM NAV"';
}
}
```

### Configure gunicorn

    vim /opt/netbox/netbox-2.4.8/netbox/gunicorn_config.py

```conf
command = '/opt/netbox/.netbox_venv/bin/gunicorn'
pythonpath = '/opt/netbox/netbox-2.4.8/netbox'
bind = '127.0.0.1:8001'
workers = 2
user = 'nginx'
```

## Supervisor configuration

    sudo yum install -y --nogpgcheck supervisor
    vim /etc/supervisord.d/netbox.ini

```conf
[program:netbox]
command = /opt/netbox/.netbox_venv/bin/gunicorn -c /opt/netbox/netbox-2.4.8/netbox/gunicorn_config.py netbox.wsgi
directory = /opt/netbox/netbox-2.4.8/netbox
user = nginx

[program:netbox-rqworker]
command = /opt/netbox/.netbox_venv/bin/python /opt/netbox/netbox-2.4.8/netbox/manage.py rqworker
user = nginx
```

## OpenLDAP configuration

    sudo yum install -y --nogpgcheck openldap-devel
    vim /opt/netbox/netbox-2.4.8/netbox/ldap_config.py

```python
import ldap

from django_auth_ldap.config import LDAPSearch, GroupOfNamesType


# Server URI
AUTH_LDAP_SERVER_URI = "<ldaps://10.117.222.105>"

# The following may be needed if you are binding to Active Directory.
AUTH_LDAP_CONNECTION_OPTIONS = {
ldap.OPT_REFERRALS: 0
}

# Set the DN and password for the NetBox service account.
AUTH_LDAP_BIND_DN = "uid=netbox,ou=serviceAccounts,dc=acc,dc=gvp=dc=org"
AUTH_LDAP_BIND_PASSWORD = "redacted"

# Include this setting if you want to ignore certificate errors. This might be needed to accept a self-signed cert.
# Note that this is a NetBox-specific setting which sets:
#     ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)
LDAP_IGNORE_CERT_ERRORS = True


# TODO

# This search matches users with the sAMAccountName equal to the provided username. This is required if the user's
# username is not in their DN (Active Directory).
# AUTH_LDAP_USER_SEARCH = LDAPSearch("ou=Users,dc=acc,dc=gvp,dc=kpn,dc=org",
#                                     ldap.SCOPE_SUBTREE,
#                                     "(sAMAccountName=%(user)s)")

# If a user's DN is producible from their username, we don't need to search.
AUTH_LDAP_USER_DN_TEMPLATE = "uid=%(user)s,ou=Users,dc=acc,dc=gvp,dc=kpn,dc=org"

# You can map user attributes to Django attributes as so.
AUTH_LDAP_USER_ATTR_MAP = {
"first_name": "givenName",
"last_name": "sn",
"email": "mail"
}

# This search ought to return all groups to which the user belongs. django_auth_ldap uses this to determine group
# hierarchy.
AUTH_LDAP_GROUP_SEARCH = LDAPSearch("ou=Groups,dc=acc,dc=gvp,dc=kpn,dc=org", ldap.SCOPE_SUBTREE,
"(objectClass=group)")
AUTH_LDAP_GROUP_TYPE = GroupOfNamesType()

# Define a group required to login.
AUTH_LDAP_REQUIRE_GROUP = "cn=netbox_users,ou=Groups,dc=acc,dc=gvp,dc=kpn,dc=org"

# Define special user types using groups. Exercise great caution when assigning superuser status.
# AUTH_LDAP_USER_FLAGS_BY_GROUP = {
#     "is_active": "cn=active,ou=groups,dc=example,dc=com",
#     "is_staff": "cn=staff,ou=groups,dc=example,dc=com",
#     "is_superuser": "cn=superuser,ou=groups,dc=example,dc=com"
# }

# For more granular permissions, we can map LDAP groups to Django groups.
AUTH_LDAP_FIND_GROUP_PERMS = True

# Cache groups for one hour to reduce LDAP traffic
AUTH_LDAP_CACHE_GROUPS = True
AUTH_LDAP_GROUP_CACHE_TIMEOUT = 3600
```

## SSL Configuration

TODO: get or create SSL certificates and update nginx

## References

- [Netbox installation guide](<https://netbox.readthedocs.io/en/latest/>)
- [Postgres backup and restore](<https://www.postgresql.org/docs/9.6/backup.html>)