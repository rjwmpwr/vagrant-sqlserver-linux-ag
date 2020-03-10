#!/bin/bash -e

errstatus=1
/opt/mssql-tools/bin/sqlcmd -S ${NODE1_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"CREATE MASTER KEY ENCRYPTION BY PASSWORD = '${CERT_MASTER_KEY}';
CREATE CERTIFICATE ag_cert WITH SUBJECT = 'ag_cert';
BACKUP CERTIFICATE ag_cert
  TO FILE = '/var/opt/mssql/data/ag_cert.cer'
  WITH PRIVATE KEY (
    FILE = '/var/opt/mssql/data/ag_cert.pvk',
    ENCRYPTION BY PASSWORD = '${CERT_PRIV_KEY}'
  );
"
errstatus=$?
if [ $errstatus = 1 ]
then
  echo Master key and Cert creation failed on ${NODE1_HOSTNAME}
  exit $errstatus
fi
chown mssql:mssql /var/opt/mssql/data/ag_cert.*

# scp cert to all other nodes
scp -p /var/opt/mssql/data/ag_cert.* ${NODE2_HOSTNAME}:/var/opt/mssql/data/
ssh ${NODE2_HOSTNAME} 'chown mssql:mssql /var/opt/mssql/data/ag_cert.*'
scp -p /var/opt/mssql/data/ag_cert.* ${NODE3_HOSTNAME}:/var/opt/mssql/data/
ssh ${NODE3_HOSTNAME} 'chown mssql:mssql /var/opt/mssql/data/ag_cert.*'

# Create the certificate on all other servers
errstatus=1
cert_q="CREATE MASTER KEY ENCRYPTION BY PASSWORD = '${CERT_MASTER_KEY}';  \
CREATE CERTIFICATE ag_cert                                                \
  FROM FILE = '/var/opt/mssql/data/ag_cert.cer'                           \
  WITH PRIVATE KEY (                                                      \
    FILE = '/var/opt/mssql/data/ag_cert.pvk',                             \
    DECRYPTION BY PASSWORD = '${CERT_PRIV_KEY}'                           \
  );                                                                      \
"
/opt/mssql-tools/bin/sqlcmd -S ${NODE2_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"${cert_q}"
errstatus=$?
if [ $errstatus = 1 ]
then
  echo Master key and Cert creation failed on ${NODE2_HOSTNAME}
  exit $errstatus
fi

errstatus=1
/opt/mssql-tools/bin/sqlcmd -S ${NODE3_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"${cert_q}"
errstatus=$?
if [ $errstatus = 1 ]
then
  echo Master key and Cert creation failed on ${NODE3_HOSTNAME}
  exit $errstatus
fi

endpoint_q="CREATE ENDPOINT [ag_endpoint]     \
  AS TCP (LISTENER_PORT = 5022)               \
  FOR DATABASE_MIRRORING (                    \
    ROLE = ALL,                               \
    AUTHENTICATION = CERTIFICATE ag_cert,     \
    ENCRYPTION = REQUIRED ALGORITHM AES       \
  );                                          \
ALTER ENDPOINT [ag_endpoint] STATE = STARTED; \
"
/opt/mssql-tools/bin/sqlcmd -S ${NODE1_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"${endpoint_q}"
/opt/mssql-tools/bin/sqlcmd -S ${NODE2_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"${endpoint_q}"
/opt/mssql-tools/bin/sqlcmd -S ${NODE3_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"${endpoint_q}"

createag_q="CREATE AVAILABILITY GROUP [${AG_NAME}]
  WITH (DB_FAILOVER = ON, CLUSTER_TYPE = EXTERNAL)
  FOR REPLICA ON
    N'${NODE1_HOSTNAME}' 
    WITH (
      ENDPOINT_URL = N'tcp://${NODE1_HOSTNAME}:5022',
      AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
      FAILOVER_MODE = EXTERNAL,
      SEEDING_MODE = AUTOMATIC,
      PRIMARY_ROLE (ALLOW_CONNECTIONS = READ_WRITE ),  
      SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY )
    ),
    N'${NODE2_HOSTNAME}' 
    WITH (
      ENDPOINT_URL = N'tcp://${NODE2_HOSTNAME}:5022',
      AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
      FAILOVER_MODE = EXTERNAL,
      SEEDING_MODE = AUTOMATIC,
      PRIMARY_ROLE (ALLOW_CONNECTIONS = READ_WRITE ),  
      SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY ) 
    ),
    N'${NODE3_HOSTNAME}' 
    WITH ( 
      ENDPOINT_URL = N'tcp://${NODE3_HOSTNAME}:5022', 
      AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
      FAILOVER_MODE = EXTERNAL,
      SEEDING_MODE = AUTOMATIC,
      PRIMARY_ROLE (ALLOW_CONNECTIONS = READ_WRITE ),  
      SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY ) 
    );
ALTER AVAILABILITY GROUP [${AG_NAME}] GRANT CREATE ANY DATABASE;
"
/opt/mssql-tools/bin/sqlcmd -S ${NODE1_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"${createag_q}"

joinag_q="ALTER AVAILABILITY GROUP [${AG_NAME}] JOIN WITH (CLUSTER_TYPE = EXTERNAL); ALTER AVAILABILITY GROUP [${AG_NAME}] GRANT CREATE ANY DATABASE;"
/opt/mssql-tools/bin/sqlcmd -S ${NODE2_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"${joinag_q}"
/opt/mssql-tools/bin/sqlcmd -S ${NODE3_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"${joinag_q}"

alter_user_q="GRANT ALTER, CONTROL, VIEW DEFINITION ON AVAILABILITY GROUP::[${AG_NAME}] TO [$PACEMAKER_USER]; GRANT VIEW SERVER STATE TO [$PACEMAKER_USER];"
/opt/mssql-tools/bin/sqlcmd -S ${NODE1_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"${alter_user_q}"
/opt/mssql-tools/bin/sqlcmd -S ${NODE2_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"${alter_user_q}"
/opt/mssql-tools/bin/sqlcmd -S ${NODE3_HOSTNAME} -U SA -P $MSSQL_SA_PASSWORD -Q \
"${alter_user_q}"
