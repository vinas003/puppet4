class docker_host {

  $packages = ['docker-engine']
  $services = ['docker']
  
  file { ['/etc/yum.repos.d/docker.repo']:
    mode    => "644",
    content => template("$name/docker.repo.erb"),
    notify  => Service[$services],
  }

  package { $packages:
    ensure => installed,
  }

  service { $services:
    ensure  => running,
    enable  => true,
    require => Package[$packages],
  }  
}
