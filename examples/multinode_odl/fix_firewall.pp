# single class declaration to apply modified firewall rules only.
# Do not touch other running modules.
node 'devcontroller.localdomain' {
  include ::openstack::role::fix_firewall
}

node 'devcompute.localdomain' {
  include ::openstack::role::fix_firewall
}

node 'devnetwork.localdomain' {
  include ::openstack::role::fix_firewall
}
