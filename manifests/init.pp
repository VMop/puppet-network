class network {
  case $::osfamily {
    'redhat': { $svc_name = 'network' }
    'debian': { $svc_name = 'networking' }
  }
  service { 'network':
    name   => $svc_name,
    ensure => running,
    enable => true,
  }
}
