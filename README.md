# strongswan_ikev2
## Install Programs
- sudo apt install strongswan netfilter-persistent strongswan-pki ufw libcharon-extra-plugins moreutils strongswan-ikev2
- sudo apt-get install strongswan strongswan-plugin-eap-mschapv2 moreutils iptables-persistent strongswan-plugin-openssl
- ( For Ubuntu 16.04.3)

 libcharon-extra-plugins libio-pty-perl libipc-run-perl libpcsclite1
  libstrongswan libtspi1 netfilter-persistent strongswan-charon
  strongswan-libcharon strongswan-starter strongswan-tnc-base???

## Fix run.bash
- Fix CN field in line 18
- Fix --san field in line 19-20
- Fix eth0 to appropriate network interface (line 61, 62 and 63)
- Save 

## Fix ipsec.conf file
- Fix line 18 (leftid field)
- Save

# Fix ipsec.secrets
- Fix line 1 server_url_or_ip_address_field
- Fix line 2 user ID and user password field
- Copy and modify line 2 to make another user ID and password
- Save

# Run
- Run **run.bash** with root user

# Reboot
- Reboot

