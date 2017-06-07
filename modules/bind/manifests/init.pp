class bind {

  $packages = ['bind']
  $services = ['named']
  
  package { $packages:
    ensure => installed,
  }

  service { 'named':
    ensure  => running,
    enable  => true,
    require => Package[$packages],
  }

  # create directories
  file { [ '/etc/named/', '/etc/named/zones/']:
    mode    => "750",
    owner   => "root",
    group   => "named",
    ensure  => directory,          # They should be directories instead of a file
    require => Package[$packages], # Before we create the directories the files the package must be installed
  }

  easy_file {
    [
     '/etc/named.conf',
     '/etc/named/named.conf.local',
     '/etc/named/zones/db.10',
     '/etc/named/zones/db.greyhash.se',
    ]:
    mode => "644",
    group => "named",
  }
}
