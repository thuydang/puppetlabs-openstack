node 'puppet' {
  include ::ntp
  class { '::puppetdb':
    listen_address     => '0.0.0.0',
    ssl_listen_address => '0.0.0.0'
  }->
  class { '::puppetdb::master::config':
    puppetdb_server => 'puppet'
  }
}

node 'devcontroller.localdomain' {
  include ::openstack::role::controller
}

# storage goes to controller node
#node 'storage.localdomain' {
#  include ::openstack::role::storage
#}

node 'devnetwork.localdomain' {
  include ::openstack::role::network
}

node 'devcompute.localdomain' {
  include ::openstack::role::compute
}

node 'swiftstore1.localdomain' {
  class { '::openstack::role::swiftstorage':
    zone => '1'
  }
}

node 'swiftstore2.localdomain' {
  class { '::openstack::role::swiftstorage':
    zone => '2'
  }
}

node 'swiftstore3.localdomain' {
  class { '::openstack::role::swiftstorage':
    zone => '3'
  }
}

node 'tempest.localdomain' {
  include ::openstack::role::tempest
}
