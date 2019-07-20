#!/bin/bash
# https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-18-04-2

DATE=`date +%Y%m%d_%H%M%S`
ADDR=xxxxxxxxxxxxxx        #TODO: Fix this
IP_ADR=xxx.xxx.xxx.xxx     #TODO: Fix this
NAT_ADPT=eth0              #TODO: Fix this
ID=user_id                 #TODO: Fix this
PASSWD=user_passwd         #TODO: Fix this


ipsec pki --gen --type rsa --size 4096 --outform pem > server-root-key.pem
chmod 600 server-root-key.pem
ipsec pki --self --ca --lifetime 3650 \
--in server-root-key.pem \
--type rsa --dn "C=US, O=VPN Server, CN=VPN Server Root CA" \
--outform pem > server-root-ca.pem

ipsec pki --gen --type rsa --size 4096 --outform pem > vpn-server-key.pem
ipsec pki --pub --in vpn-server-key.pem \
--type rsa | ipsec pki --issue --lifetime 1825 \
--cacert server-root-ca.pem \
--cakey server-root-key.pem \
--dn "C=US, O=VPN Server, CN=server_address_or_ip" \
--san server_address \
--san server_ip_not_mandatory \
--flag serverAuth --flag ikeIntermediate \
--outform pem > vpn-server-cert.pem
cp vpn-server-cert.pem /etc/ipsec.d/certs/vpn-server-cert.pem
cp vpn-server-key.pem /etc/ipsec.d/private/vpn-server-key.pem
chown root /etc/ipsec.d/private/vpn-server-key.pem
chgrp root /etc/ipsec.d/private/vpn-server-key.pem
chmod 600 /etc/ipsec.d/private/vpn-server-key.pem

 openssl pkcs12 -export -out server-root-ca.p12 -in vpn-server-cert.pem -inkey vpn-server-key.pem -certfile server-root-ca.pem

############
cp /etc/ipsec.conf    /etc/ipsec.conf.original_${DATE}
cp /etc/ipsec.secrets /etc/ipsec.secrets.original_${DATE}
cp -rf ref ref_original_${DATE}

sed -i -e 's@server_url_or_ip_address@m_user_addr@g' ref/ipsec.conf
sed -i -e 's@server_url_or_ip_address@m_user_addr@g' ref/ipsec.secrets
sed -i -e 's@user_id@m_user_id@g'                    ref/ipsec.secrets
sed -i -e 's@user_passwd@m_user_passwd@g'            ref/ipsec.secrets

echo '' | tee /etc/ipsec.conf
cp ref/ipsec.conf /etc/ipsec.conf
echo '' | tee /etc/ipsec.secrets
cp ref/ipsec.secrets /etc/ipsec.secrets
ipsec reload
systemctl restart strongswan

ufw allow OpenSSH
ufw enable
ufw allow 500,4500/udp
ufw allow 80/tcp
ufw allow 20/tcp
ufw allow 21/tcp
ufw allow 990/tcp
ufw allow 40000:50000/tcp
cp /etc/ufw/before.rules /etc/ufw/before.rules_${DATE}
sed -i -e 's@*filter@*nat\n-A POSTROUTING -s 10.10.10.0/24 -o '${NAT_ADPT}' -m policy --pol ipsec --dir out -j ACCEPT\n-A POSTROUTING -s 10.10.10.0/24 -o '${NAT_ADPT}' -j MASQUERADE\nCOMMIT\n\n*mangle\n-A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o '${NAT_ADPT}' -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360\nCOMMIT\n\n*filter@' /etc/ufw/before.rules
sed -i -e 's@# End required lines@# End required lines\n\n-A ufw-before-forward --match policy --pol ipsec --dir in  --proto esp -s 10.10.10.0/24 -j ACCEPT\n-A ufw-before-forward --match policy --pol ipsec --dir out --proto esp -d 10.10.10.0/24 -j ACCEPT@' /etc/ufw/before.rules
cp /etc/sysctl.conf sysctl_backup_${DATE}.conf
echo "net.ipv4.ip_forward = 1"                          |  tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects = 0"           |  tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0"             |  tee -a /etc/sysctl.conf
echo "net.ipv4.ip_no_pmtu_disc = 1"                     |  tee -a /etc/sysctl.conf
ufw disable
ufw enable
