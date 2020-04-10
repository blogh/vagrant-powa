#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

while getopts "v:" option; do
    case "${option}" in
        v) PGVER="${OPTARG}" ;;
    esac
done

PGBINDIR="/usr/pgsql-${PGVER}/bin"
PGDATA="/var/lib/pgsql/${PGVER}/data"

echo "=> Install powa client"
if ! rpm --quiet -q "pgdg-redhat-repo"; then
    yum install --nogpgcheck --quiet -y -e 0 "https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
fi

PACKAGES=(
    "powa_${PGVER}" "pg_qualstats${PGVER}" "pg_stat_kcache${PGVER}" "hypopg_${PGVER}"
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"

echo "=> Update Postgres install & restart"
cat <<EOF >>${PGDATA}/postgresql.conf
shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'
EOF

sed -i "/# TYPE  DATABASE        USER            ADDRESS                 METHOD/a\
host    powa            powa            ::1/128                 md5" "${PGDATA}/pg_hba.conf"

sudo systemctl restart postgresql-${PGVER}

echo "=> Create DB & USER & EXTRENSIONS"
sudo -iu postgres ${PGBINDIR}/psql <<EOF
CREATE ROLE powa WITH SUPERUSER LOGIN PASSWORD 'password';
CREATE DATABASE powa OWNER powa;
\c powa
CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION btree_gist;
CREATE EXTENSION powa;
CREATE EXTENSION pg_qualstats;
CREATE EXTENSION pg_stat_kcache;
CREATE EXTENSION hypopg;
EOF

