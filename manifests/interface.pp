define network::interface (
  $ensure      = 'present',
  $ipaddress   = undef,
  $netmask     = undef,
  $method      = undef,
  $family      = undef,
  $onboot      = undef,
  $hotplug     = undef,
  $reconfigure = undef,
  $options     = undef,
) {
  include network

  network_config { $name:
    ensure      => $ensure,
    ipaddress   => $ipaddress,
    netmask     => $netmask,
    method      => $method,
    family      => $family,
    onboot      => $onboot,
    hotplug     => $hotplug,
    reconfigure => $reconfigure,
    options     => $options,
    notify      => Service['network'],
  }
}
