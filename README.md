# vagrant-sqlserver-linux-ag
Microsoft SQLServer 2019 with AlwaysOn Availability Group running on 3 node Oracle Linux cluster

The idea of these 2 vagrant builds came from oracle-base.com's Oracle 19c RAC build with virtualbox and vagrant
(https://oracle-base.com/articles/19c/oracle-db-19c-rac-installation-on-oracle-linux-7-using-virtualbox#description-of-the-build).

Required Software:
1. vagrant: https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_x86_64.msi
2. virtualbox: https://www.virtualbox.org/wiki/Downloads
3. git client

Recommended vagrant plugin:
vagrant plugin install vagrant-vbguest

Description of build:
ol7_ag and ol8_ag, each will contain 4 nodes, one dns node, 3 sqlserver nodes running either oracle linux 7 or oracle linux 8 with Microsoft Sqlserver 2019.  DNS node will require 1gb of ram.  Each of sqlserver nodes will require 4gb of ram.

Clone Repository:
1. Create a folder on your host to store the repo.
2. to clone the repo, do the following:

git clone https://github.com/rjwmpwr/vagrant-sqlserver-linux-ag.git

Typically, I will copy the repo files to another folder, such as d:\VM\ol8_ag or d:\VM\ol7_ag
Note: make sure your git client maintain UNIX style line terminators.  All scripts are run inside the Linux VMs.  Without UNIX style line terminators, scripts will error out.

To start,
1. download the box, do the following:

vagrant box add --name ol8 https://yum.oracle.com/boxes/oraclelinux/ol80/ol80.box

vagrant box add --name ol7 https://yum.oracle.com/boxes/oraclelinux/latest/ol7-latest.box

2. bring up vagrant boxes.  Important:  node 1 needs to be brought up the last.  That is where the cluseter and the availability group will be built.

cd d:\vm\ol7_ag\dns

vagrant up

cd d:\vm\ol7_ag\node3

vagrant up

cd d:\vm\ol7_ag\node2

vagrant up

cd d:\vm\ol7_ag\node1

vagrant up
