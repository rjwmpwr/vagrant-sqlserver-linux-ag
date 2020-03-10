. /vagrant_config/install.env

cat > /etc/resolv.conf <<EOF
search localdomain
nameserver ${DNS_PUBLIC_IP}
EOF

echo "******************************************************************************"
echo "Set Hostname." `date`
echo "******************************************************************************"
hostname ${NODE1_FQ_HOSTNAME}
cat > /etc/hostname <<EOF
${NODE1_FQ_HOSTNAME}
EOF

sh /vagrant_scripts/configure_hosts_base.sh

sh /vagrant_scripts/configure_chrony.sh

sh /vagrant_scripts/prepare_u01_disk.sh

echo "******************************************************************************"
echo "Prep passwordless SSH Setup for root." `date`
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

ssh ${NODE1_HOSTNAME} date
echo "${ROOT_PASSWORD}" > /tmp/temp.txt

echo "******************************************************************************"
echo "SQLServer Installation." `date`
echo "******************************************************************************"
sh /vagrant_scripts/install_sql.sh

echo "******************************************************************************"
echo "Prepping for AG setup." `date`
echo "******************************************************************************"
sh /vagrant_scripts/prep_ag.sh

echo "******************************************************************************"
echo "Passwordless SSH Setup for root." `date`
echo "******************************************************************************"
ssh-keyscan -H ${NODE1_HOSTNAME} >> ~/.ssh/known_hosts
ssh-keyscan -H ${NODE2_HOSTNAME} >> ~/.ssh/known_hosts
ssh-keyscan -H ${NODE3_HOSTNAME} >> ~/.ssh/known_hosts

sshpass -f /tmp/temp.txt ssh-copy-id ${NODE2_HOSTNAME}
sshpass -f /tmp/temp.txt ssh-copy-id ${NODE3_HOSTNAME}

cat > /tmp/ssh2-setup.sh <<EOF
ssh-keyscan -H ${NODE1_HOSTNAME} >> ~/.ssh/known_hosts
ssh-keyscan -H ${NODE2_HOSTNAME} >> ~/.ssh/known_hosts
ssh-keyscan -H ${NODE3_HOSTNAME} >> ~/.ssh/known_hosts
sshpass -f /tmp/temp.txt ssh-copy-id ${NODE1_HOSTNAME}
sshpass -f /tmp/temp.txt ssh-copy-id ${NODE3_HOSTNAME}
EOF
ssh ${NODE2_HOSTNAME} 'bash -s' < /tmp/ssh2-setup.sh

cat > /tmp/ssh3-setup.sh <<EOF
ssh-keyscan -H ${NODE1_HOSTNAME} >> ~/.ssh/known_hosts
ssh-keyscan -H ${NODE2_HOSTNAME} >> ~/.ssh/known_hosts
ssh-keyscan -H ${NODE3_HOSTNAME} >> ~/.ssh/known_hosts
sshpass -f /tmp/temp.txt ssh-copy-id ${NODE1_HOSTNAME}
sshpass -f /tmp/temp.txt ssh-copy-id ${NODE2_HOSTNAME}
EOF
ssh ${NODE3_HOSTNAME} 'bash -s' < /tmp/ssh3-setup.sh

echo "******************************************************************************"
echo "Create Linux Cluster." `date`
echo "******************************************************************************"
sh /vagrant_scripts/create_cluster.sh

echo "******************************************************************************"
echo "Create AG." `date`
echo "******************************************************************************"
sh /vagrant_scripts/create_ag.sh

echo "******************************************************************************"
echo "setting cluster property on all nodes." `date`
echo "******************************************************************************"
sh /vagrant_scripts/set_cluster_prop.sh
ssh ${NODE2_HOSTNAME} 'bash -s' < /vagrant_scripts/set_cluster_prop.sh
ssh ${NODE3_HOSTNAME} 'bash -s' < /vagrant_scripts/set_cluster_prop.sh

echo "******************************************************************************"
echo "create cluster resource." `date`
echo "******************************************************************************"
sh /vagrant_scripts/create_cluster_resource.sh

echo "******************************************************************************"
echo "create database and add to availability group." `date`
echo "******************************************************************************"
sh /vagrant_scripts/add_db2ag.sh