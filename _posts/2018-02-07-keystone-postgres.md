---
title:  "Deploying Keystone using PosgreSQL"
date:   2018-02-07 12:12:38 +0100
---

OpenStack is becoming more and more flexible on how you can configure it. One straightforward example is by switching from the default MySQL/MariaDB database to PostgreSQL.

In `/etc/keystone/keystone.conf` configure the database section:

```bash
...

[database]
connection = postgresql://keystone:Paasw0rd@openstack_postgresql/keystone

...
```

Install the necessary packages:

```bash
pacman -Sy --noconfirm postgresql python-psycopg2 python-sqlalchemy
```

Create the database user for keystone:

```bash
export PGPASSWORD=PG_Paasw0rd

psql -h openstack_postgresql -p 5432 -v ON_ERROR_STOP=1 --username "admin" <<-EOSQL
    CREATE USER keystone;
    ALTER USER keystone WITH PASSWORD 'Paasw0rd';
    CREATE DATABASE keystone;
    GRANT ALL PRIVILEGES ON DATABASE keystone TO keystone;
EOSQL
```

And then, business as usual.