#!/bin/bash -e

echo "******************************************************************************"
echo "Prep for cluster setup." `date`
echo "******************************************************************************"

echo "******************************************************************************"
echo "Enable SQL Server Always On Availability Groups feature"  `date`
echo "******************************************************************************"
/opt/mssql/bin/mssql-conf set hadr.hadrenabled  1  
systemctl restart mssql-server  

echo "******************************************************************************"
echo "Enable an AlwaysOn_health event session"  `date`
echo "******************************************************************************"
/opt/mssql-tools/bin/sqlcmd \
  -S localhost \
  -U SA \
  -P $MSSQL_SA_PASSWORD \
  -Q "ALTER EVENT SESSION  AlwaysOn_health ON SERVER WITH (STARTUP_STATE=ON)"

echo "******************************************************************************"
echo "Create pacemakerlogin"  `date`
echo "******************************************************************************"
/opt/mssql-tools/bin/sqlcmd \
  -S localhost \
  -U SA \
  -P $MSSQL_SA_PASSWORD \
  -Q "CREATE LOGIN [$PACEMAKER_USER] WITH PASSWORD=N'$PACEMAKER_USER_PASSWORD', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON; ALTER SERVER ROLE [sysadmin] ADD MEMBER [$PACEMAKER_USER]"

echo "$PACEMAKER_USER" >> ~/pacemaker-passwd
echo "$PACEMAKER_USER_PASSWORD" >> ~/pacemaker-passwd
mv ~/pacemaker-passwd /var/opt/mssql/secrets/passwd
chown root:root /var/opt/mssql/secrets/passwd
chmod 400 /var/opt/mssql/secrets/passwd # Only readable by root

echo "******************************************************************************"
echo "Set hacluster password" `date`
echo "******************************************************************************"
echo -e "${HACLUSTER_PASSWORD}\n${HACLUSTER_PASSWORD}" | passwd hacluster

echo "******************************************************************************"
echo "Open the Pacemaker firewall ports" `date`
echo "******************************************************************************"
firewall-cmd --zone=public --add-port=5022/tcp --permanent  
firewall-cmd --add-service=high-availability --zone=public --permanent  
firewall-cmd --reload
firewall-cmd --permanent --zone=public --list-all

echo "******************************************************************************"
echo "Start pcs daemon" `date`
echo "******************************************************************************"
systemctl enable pcsd
systemctl start pcsd
systemctl enable pacemaker
systemctl enable corosync
