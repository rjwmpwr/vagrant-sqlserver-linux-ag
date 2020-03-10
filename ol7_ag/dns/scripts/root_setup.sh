. /vagrant_config/install.env

echo "******************************************************************************"
echo "Set Hostname." `date`
echo "******************************************************************************"
hostname ${DNS_FQ_HOSTNAME}
cat > /etc/hostname <<EOF
${DNS_FQ_HOSTNAME}
EOF

sh /vagrant_scripts/configure_hosts_base.sh

echo "******************************************************************************"
echo "Install dnsmasq." `date`
echo "******************************************************************************"
yum install -y dnsmasq
systemctl enable dnsmasq
systemctl restart dnsmasq
