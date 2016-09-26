class bash {

  $packages = ['bash']
  
  package { $packages:
    ensure => installed,
  }

  file { "/root/.bashrc":
    mode     => "644",
    content  => template('bash/bashrc.erb'),
  }
  
  file { '/home/centos/.bashrc':
    owner    => centos,
    group    => centos,
    mode     => "644",
    content  => template('bash/bashrc.erb'),
  }
}

