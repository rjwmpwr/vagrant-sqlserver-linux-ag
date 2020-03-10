#!/bin/bash -e

if [ -z $MSSQL_SA_PASSWORD ]
then
  echo Environment variable MSSQL_SA_PASSWORD must be set for unattended install
  exit 1
fi

echo "******************************************************************************"
echo "Adding Microsoft repositories..."  `date`
echo "******************************************************************************"
curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/7/mssql-server-2019.repo
curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/7/prod.repo

echo "******************************************************************************"
echo "Install Linux cluster packages." `date`
echo "******************************************************************************"
yum install -y -q yum-utils
yum install -y -q sshpass zip unzip
yum install -y -q pacemaker pcs fence-agents-all resource-agents

echo "******************************************************************************"
echo "Install SQL Server." `date`
echo "******************************************************************************"
yum install -y -q mssql-server
yum install -y -q mssql-server-ha  

echo "******************************************************************************"
echo "Running mssql-conf setup." `date`
echo "******************************************************************************"
MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD \
     MSSQL_PID=$MSSQL_PID \
     /opt/mssql/bin/mssql-conf -n setup accept-eula

echo "******************************************************************************"
echo "Installing mssql-tools and unixODBC developer." `date`
echo "******************************************************************************"
ACCEPT_EULA=Y yum install -y mssql-tools unixODBC-devel

# Add SQL Server tools to the path by default:
echo Adding SQL Server tools to your path...
echo PATH="$PATH:/opt/mssql-tools/bin" >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

# Optional Enable SQL Server Agent :
if [ ! -z $SQL_ENABLE_AGENT ]
then
  echo Enable SQL Server Agent...
  /opt/mssql/bin/mssql-conf set sqlagent.enabled true
  systemctl restart mssql-server
fi

# Optional SQL Server Full Text Search installation:
if [ ! -z $SQL_INSTALL_FULLTEXT ]
then
  echo Installing SQL Server Full-Text Search...
  yum install -y -q mssql-server-fts
fi

echo "******************************************************************************"
echo "Enable firewalld." `date`
echo "******************************************************************************"
# enable firewalld
systemctl enable firewalld
systemctl start firewalld

echo "******************************************************************************"
echo "Configuring firewall to allow traffic on port 1433." `date`
echo "******************************************************************************"
# Configure firewall to allow TCP port 1433:
firewall-cmd --zone=public --add-port=1433/tcp --permanent
firewall-cmd --reload

# Example of setting post-installation configuration options
# Set trace flags 1204 and 1222 for deadlock tracing:
#echo Setting trace flags...
# /opt/mssql/bin/mssql-conf traceflag 1204 1222 on

# Restart SQL Server after making configuration changes:
echo Restarting SQL Server...
systemctl restart mssql-server

# Connect to server and get the version:
counter=1
errstatus=1
while [ $counter -le 5 ] && [ $errstatus = 1 ]
do
  echo Waiting for SQL Server to start...
  sleep 5s
  /opt/mssql-tools/bin/sqlcmd \
    -S localhost \
    -U SA \
    -P $MSSQL_SA_PASSWORD \
    -Q "SELECT @@VERSION" 2>/dev/null
  errstatus=$?
  ((counter++))
done

# Display error if connection failed:
if [ $errstatus = 1 ]
then
  echo Cannot connect to SQL Server, installation aborted
  exit $errstatus
fi

# Optional new user creation:
if [ ! -z $SQL_INSTALL_USER ] && [ ! -z $SQL_INSTALL_USER_PASSWORD ]
then
  echo Creating user $SQL_INSTALL_USER
  /opt/mssql-tools/bin/sqlcmd \
    -S localhost \
    -U SA \
    -P $MSSQL_SA_PASSWORD \
    -Q "CREATE LOGIN [$SQL_INSTALL_USER] WITH PASSWORD=N'$SQL_INSTALL_USER_PASSWORD', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON; ALTER SERVER ROLE [sysadmin] ADD MEMBER [$SQL_INSTALL_USER]"
fi

echo Done!