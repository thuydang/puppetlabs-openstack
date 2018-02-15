====== Deploying Openstack with Puppet ======
  * puppet learning: https://docs.puppetlabs.com/learning/modules1.html
  * puppet basic: http://www.cybera.ca/news-and-events/tech-radar/lets-build-cloud-puppet
  * puppet opnestack: http://www.cybera.ca/news-and-events/tech-radar/lets-build-cloud-using-puppet-install-openstack
  * https://forge.puppetlabs.com/puppetlabs/openstack#setup-requirements
  * http://behindtheracks.com/2014/11/openstack-juno-scripted-install-with-neutron-on-centos-7/

====== Network Infrastructure ======
https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/5/html/Cloud_Administrator_Guide/section_networking-arch.html


**Note** This same procedure is tested with 2 Nodes Controller + Compute and Controller+Compute+Network.
Test with ODL not succesful.
====== Infrastructure description ======
Controller:
  * ens3: 10.10.11.2    <----- api net
  * ens4: 10.20.21.2    <----- mgmt net & data net
  * ens5: dhcp          <----- ext net

Compute:
  * ens3: 10.10.11.3    <----- api net
  * ens4: 10.20.21.3    <----- mgmt net & data net
  * ens5: dhcp          <----- ext net

network:
  * ens3: 10.10.11.5    <----- api net
  * ens4: 10.20.21.5    <----- mgmt net & data net
  * ens5: dhcp          <----- ext net

====== Download puppetlab openstack ======
Version: Version 4.2.0 released Oct 22nd 2014

<code>
Puppet Module :: OpenStack Version :: OpenStack Codename
2.0.0         -> 2013.1.0          -> Grizzly
3.0.0         -> 2013.2.0          -> Havana
4.0.0         -> 2014.1.0          -> Icehouse
5.0.0         -> 2014.2.0          -> Juno
</code>

    yum install puppet -y
    puppet module install puppetlabs-openstack --version 4.2.0
    
===== Configure Hiera =====
    vim /etc/puppet/hiera.yaml
    ---
    :backends:
      - yaml
    :hierarchy:
      - defaults
      - "%{clientcert}"
      - "%{environment}"
      - global
      - common

    :yaml:
    # When specifying a datadir, make sure the directory exists.
    :datadir: /etc/puppet/hieradata
    
    mkdir -p /etc/puppet/hieradata
    cp /etc/puppet/modules/openstack/examples/common.yaml /etc/puppet/hieradata/
    
    
====== Hiera.yml ======
Configuration detail for all nodes.

<code>
cat /etc/puppet/hieradata/common.yaml 
openstack::region: 'openstack'

######## Networks
openstack::network::api: '192.168.201.0/24'
openstack::network::external: '192.168.201.0/24'
openstack::network::management: '10.10.11.0/24'
openstack::network::data: '10.20.21.0/24'

openstack::network::external::ippool::start: 192.168.201.100
openstack::network::external::ippool::end: 192.168.201.200
openstack::network::external::gateway: 192.168.201.1
openstack::network::external::dns: 192.168.201.1

######## Private Neutron Network

openstack::network::neutron::private: '10.0.0.0/24'

######## Fixed IPs (controllers)

openstack::controller::address::api: '192.168.201.29'
openstack::controller::address::management: '10.10.11.2'
openstack::storage::address::api: '192.168.201.29'
openstack::storage::address::management: '10.10.11.2'

######## Database

openstack::mysql::root_password: 'mysqlroot'
openstack::mysql::service_password: 'mysqlservice'
openstack::mysql::allowed_hosts: ['localhost', '127.0.0.1', 'devcontroller', 'devcompute']

######## RabbitMQ

openstack::rabbitmq::user: 'openstack'
openstack::rabbitmq::password: 'pose-vix'

######## Keystone

openstack::keystone::admin_token: 'keystonetoken'
openstack::keystone::admin_email: 'td@puppetlabs.com'
openstack::keystone::admin_password: 'admin'

openstack::keystone::tenants:
    "demo":
        description: "Demo tenant"

# admin user is configured above!
openstack::keystone::users:
    "demo":
        password: "demo"
        tenant: "demo"
        email: "demo@example.com"
        admin: false
    "test":
        password: "test"
        tenant: "demo"
        email: "test@example.com"
        admin: false

######## Glance

openstack::glance::password: 'glancePass'

######## Cinder

openstack::cinder::password: 'cinderPass'
openstack::cinder::volume_size: '28G'

######## Swift

openstack::swift::password: 'dexc-flo'
openstack::swift::hash_suffix: 'pop-bang'

######## Nova

openstack::nova::libvirt_type: 'kvm'
openstack::nova::password: 'novaPass'

######## Neutron

openstack::neutron::password: 'neutronPass'
openstack::neutron::shared_secret: 'neutronsharedsecret'

######## Ceilometer
openstack::ceilometer::mongo::password: 'mongoroot'
openstack::ceilometer::password: 'ceilometerPass'
openstack::ceilometer::meteringsecret: 'ceilometersecretkey'

######## Heat
openstack::heat::password: 'heatPass'
openstack::heat::encryption_key: 'heatsecretkey'


######## Horizon

openstack::horizon::secret_key: 'horizonsecretkey'

######## Tempest

openstack::tempest::configure_images    : true
openstack::tempest::image_name          : 'Cirros'
openstack::tempest::image_name_alt      : 'Cirros'
openstack::tempest::username            : 'demo'
openstack::tempest::username_alt        : 'test'
openstack::tempest::username_admin      : 'admin'
openstack::tempest::configure_network   : true
openstack::tempest::public_network_name : 'public-net'
openstack::tempest::cinder_available    : false
openstack::tempest::glance_available    : true
openstack::tempest::horizon_available   : true
openstack::tempest::nova_available      : true
openstack::tempest::neutron_available   : true
openstack::tempest::heat_available      : true
openstack::tempest::swift_available     : false

######## Log levels
openstack::verbose: 'True'
openstack::debug: 'True'

</code>    
====== Prepare role for Controller node ======
    cp /etc/puppet/modules/openstack/manifests/role/controller.pp /etc/puppet/modules/openstack/manifests/role/mycontroller.pp
    
    vim /etc/puppet/modules/openstack/manifests/role/mycontroller.pp
    
    # change class name
    class openstack::role::mycontroller inherits ::openstack::role {
    # comment out 
    #class { '::openstack::profile::cinder::api': } ->
    ## Add glance api from storage node
    class { '::openstack::profile::glance::api': } ->

Try other option:
    ## Add from storage
    class { '::openstack::profile::glance::api': }                                        
    class { '::openstack::profile::cinder::volume': }                                     
                                                                                        
    class { '::openstack::setup::cirros': }  
====== Prepare role for Compute node ======
    cp /etc/puppet/modules/openstack/manifests/role/compute.pp /etc/puppet/modules/openstack/manifests/role/mycompute.pp
    
====== site.pp ======
<code>
cat /etc/puppet/manifests/site.pp
node 'devcontroller' {
  include ::openstack::role::mycontroller
}

node 'devcompute' {
  include ::openstack::role::mycompute
}

</code>

On all Nodes:
    puppet apply --verbose /etc/puppet/manifests/site.pp
    puppet apply --debug --verbose /etc/puppet/manifests/site.pp
    
openrc file for admin is generated under /root/openrc
    cp /root/openrc admin_openrc
====== Troubleshooting ======
===== 3 Nodes Setting when Mgnt-net is the same as API net =====
OVS-Local-IP (Mgmt-net) must be set on controller node, which is not available!!.

Solution: Disable tunneling on **controller node only** and enable later manually??? 
    in hierardata/common.yaml
    neutron:tunneling:False
    
===== Error: Could not find dependent Exec[yum_refresh] for Yumrepo[rdo-release] at /etc/puppet/modules/openstack/manifests/resources/repo/rdo.pp:25 =====

    vim /etc/puppet/modules/openstack/manifests/resources/repo/rdo.pp
    include openstack::resources::repo::epel
    # add this line
    include openstack::resources::repo::yum_refresh

===== erlang repo not available =====
Edit 
      vim /etc/puppet/modules/openstack/manifests/resources/repo/erlang.pp
      
      #baseurl  => "http://binaries.erlang-solutions.com/rpm/${dist}/${osver}/x86_64",
      baseurl  => "http://binaries.erlang-solutions.com/rpm/centos/7/x86_64",

===== erlang can not be installed on Fedora 20 =====
  * https://openstack.redhat.com/Workarounds

Install erlang first by hand
    yum --enablerepo=updates-testing  install -y erlang-sd_notify-0.1-4   
===== sync db =====
    nova-manage db sync
    ...
===== Reinstall Keystone =====
    yum erase openstack-keystone
    puppet apply --verbose /etc/puppet/manifests/site.pp
    
===== Neutron not starts first time after installed =====
One who attempts to intall Neutron on Juno without running a neutron-db-manage will no be able to start neutron-server and may see the following error or similar in /var/log/neutron/server.log:

ProgrammingError: (ProgrammingError) (1146, "Table 'neutron.ml2_gre_allocations' doesn't exist") 'SELECT ml2_gre_allocations.gre_id AS ml2_gre_allocations_gre_id, ml2_gre_allocations.allocated AS ml2_gre_allocations_allocated \nFROM ml2_gre_allocations' ()

To fix the issue, run the following prior to starting neutron-server:

    sudo neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade juno
Credit: http://www.madorn.com/juno-neutron-server-not-starting.html#.VPcHF8tXaCg
