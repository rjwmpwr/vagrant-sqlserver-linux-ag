echo "******************************************************************************"
echo "Prepare /u01 disk." `date`
echo "******************************************************************************"
# New partition for the whole disk.
echo -e "n\np\n1\n\n\nw" | fdisk /dev/sdb

# Add file system.
mkfs.xfs -f /dev/sdb1

# Mount it.
#UUID=`blkid -o value /dev/sdb1 | grep -v xfs`
UUID=`blkid -o list /dev/sdb1 | awk '{print $NF}' | tail -n 1`
mkdir /u01
cat >> /etc/fstab <<EOF
UUID=${UUID}  /u01    xfs    defaults 1 2
EOF
mount /u01
