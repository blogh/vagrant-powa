#!/usr/bin/env bash                                                             
                                                                                
set -o errexit                                                                  
set -o nounset                                                                  
set -o pipefail                                                                 
                                                                                
declare -a PGSQL                                                                
                                                                                
while getopts "v:p:" option; do                                                 
    case "${option}" in                                                         
        v) PGVER="${OPTARG}" ;;                                                 
        p) PGSQL[${#PGSQL[@]}]=$OPTARG ;;
    esac                                                                        
done                                                                            

PGBINDIR="/usr/pgsql-${PGVER}/bin"
PGDATA="/var/lib/pgsql/${PGVER}/data"
                                                                                
echo "=> Install powa-web"
if ! rpm --quiet -q "pgdg-redhat-repo"; then                                    
    yum install --nogpgcheck --quiet -y -e 0 "https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
fi                                                                              
                                                                                
PACKAGES=(                                                                      
    python2-psycopg2
    "powa_${PGVER}-web"
)                                                                                  
                                                                                   
yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"                          

echo "=> set configuration in /etc/powa-web.conf"
cat <<EOF >/etc/powa-web.conf
servers={
  'main': {
    'host': 'localhost',
    'port': '5432',
    'database': 'powa'
  },
EOF

for N in "${PGSQL[@]}"; do
    HOST="${N%=*}"
    IP="${N##*=}"

    cat <<EOF >>/etc/powa-web.conf
  '$HOST': {
    'host': '$IP',
    'port': '5432',
    'database': 'powa'
  },
EOF
done

cat <<EOF >>/etc/powa-web.conf
}
cookie_secret="SUPERSECRET_THAT_YOU_SHOULD_CHANGE"
EOF

echo "=> configure firewall"
systemctl --quiet --now enable firewalld
firewall-cmd --quiet --permanent --new-service=powa
firewall-cmd --quiet --permanent --service=powa --set-short=powa
firewall-cmd --quiet --permanent --service=powa --set-description="powa server"
firewall-cmd --quiet --permanent --service=powa --add-port=8888/tcp
firewall-cmd --quiet --permanent --add-service=powa
firewall-cmd --quiet --reload

echo "=> Start powa-web"
systemctl start powa-web-11.service 
systemctl enable powa-web-11.service 

