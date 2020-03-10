. /vagrant_config/install.env

cat > /etc/resolv.conf <<EOF
search localdomain
nameserver ${DNS_PUBLIC_IP}
EOF

echo "******************************************************************************"
echo "Set Hostname." `date`
echo "******************************************************************************"
hostname ${NODE2_FQ_HOSTNAME}
cat > /etc/hostname <<EOF
${NODE2_FQ_HOSTNAME}
EOF

sh /vagrant_scripts/configure_hosts_base.sh

sh /vagrant_scripts/configure_chrony.sh

sh /vagrant_scripts/prepare_u01_disk.sh

echo "******************************************************************************"
echo "Passwordless SSH Setup for root." `date`
echo "******************************************************************************"
#sed -e "s/#\?PubkeyAuthentication .*/PubkeyAuthentication yes/g" -i /etc/ssh/sshd_config
grep -q "^[^#]*PasswordAuthentication" /etc/ssh/sshd_config && sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config || echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
systemctl restart sshd

echo -e "${ROOT_PASSWORD}\n${ROOT_PASSWORD}" | passwd
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cd ~/.ssh
rm -f *
cat /dev/zero | ssh-keygen -t rsa -q -N "" > /dev/null
cat id_rsa.pub >> authorized_keys
chmod 600 authorized_keys

ssh ${NODE2_HOSTNAME} date
echo "${ROOT_PASSWORD}" > /tmp/temp.txt

echo "******************************************************************************"
echo "SQLServer Installation." `date`
echo "******************************************************************************"
sh /vagrant_scripts/install_sql.sh

echo "******************************************************************************"
echo "Prepping for AG setup." `date`
echo "******************************************************************************"
sh /vagrant_scripts/prep_ag.sh
