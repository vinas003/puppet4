class activemq {

  $packages = ['activemq']
  $services = ['activemq']
  
  package { $packages:
    ensure => installed,
  }

  easy_file { "/etc/activemq/activemq.xml":
  }
  
  service { $services:
    ensure  => running,
    enable  => true,
    require => Package[$packages],
    }
}
