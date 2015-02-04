class openstack::role::fix_firewall inherits ::openstack::role {
  class { '::openstack::profile::firewall': }
}
