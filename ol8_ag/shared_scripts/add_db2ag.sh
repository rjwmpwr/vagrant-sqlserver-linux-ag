#!/bin/bash -e

errstatus=1
/opt/mssql-tools/bin/sqlcmd -S ${NODE1_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"CREATE DATABASE [${DB_NAME}];
ALTER DATABASE [${DB_NAME}] SET RECOVERY FULL;
BACKUP DATABASE [${DB_NAME}] TO DISK = N'/var/opt/mssql/data/${DB_NAME}.bak';
ALTER AVAILABILITY GROUP [${AG_NAME}] ADD DATABASE [${DB_NAME}];"
errstatus=$?
if [ $errstatus = 1 ]
then
  echo Add database to Availability Group failed on ${NODE1_HOSTNAME}
  exit $errstatus
fi
