# = Define: network::bond::setup
#
# Instantiate bonded interfaces on Redhat based systems.
#
# == See also
#
# * Red Hat Deployment Guide 25.7.2 "Using Channel Bonding"
#   https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/
#   html/Deployment_Guide/sec-Using_Channel_Bonding.html
#
class network::bond::setup {

  case $::osfamily {
    RedHat: {
      # Redhat installs the ifenslave command with the iputils package which
      # is available by default
    }
    Debian: {
      package { 'ifenslave-2.6':
        ensure => present,
      }
    }
    default {
      fail("Module ${module_name} is not supported on ${::osfamily}")
    }
  }
}
