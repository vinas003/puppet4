class ntp {

  $packages = ['ntp']
  $services = ['ntpd']
  
  package { $packages:
    ensure => installed,
  }

  service { $services:
    ensure  => running,
    enable  => true,
    require => Package[$packages],
  }

  # Set the timezone
  file { '/etc/localtime':
    ensure => link,
    target => '/usr/share/zoneinfo/Europe/Stockholm',
  }
}
