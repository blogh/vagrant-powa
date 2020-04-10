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

echo "=> Install packages"
if ! rpm --quiet -q "pgdg-redhat-repo"; then
    yum install --nogpgcheck --quiet -y -e 0 "https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
fi

PACKAGES=(
    screen vim gcc epel-release
    "postgresql${PGVER}" "postgresql${PGVER}-contrib" "postgresql${PGVER}-server"
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"

# These packages need the EPEL repo
yum install --nogpgcheck --quiet -y -e 0 python3-pip python3-devel python3-psycopg2

echo "=> Setting Firewall"
systemctl --quiet --now enable firewalld
firewall-cmd --quiet --permanent --add-service=postgresql
firewall-cmd --quiet --reload

echo "=> Creating PostgreSQL instance & modifying configuration"
${PGBINDIR}/postgresql-${PGVER}-setup initdb

cat <<EOF >>${PGDATA}/postgresql.conf
listen_addresses = '*'
EOF

sed -i "/# TYPE  DATABASE        USER            ADDRESS                 METHOD/a\
host    all             all             0.0.0.0/0               md5" "${PGDATA}/pg_hba.conf"

echo "=> Starting instance"
sudo systemctl start postgresql-${PGVER}
sudo systemctl enable postgresql-${PGVER}
