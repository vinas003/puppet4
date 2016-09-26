class nfs {

  $packages = ['autofs']
  $services = ['autofs']

  # For all NFS servers
  if ($hostname =~ /^nfs/) { 

    package { 'nfs-utils':
      ensure => installed,
    }

    service { ['nfs-server', 'nfs-config']:
      ensure  => running,
      enable  => true,
      require => Package['nfs-utils'],
    }

    # The template that uses the rules above
    file { ['/etc/sysconfig/nfs']:
      mode    => 644,
      notify  => Service['nfs-config'], # It should notify the service if the file changes
      require => Package['nfs-utils'],
      content => template("$module_name/nfs.erb"),
    }
    
    # The template that uses the rules above
    file { ['/etc/exports']:
      mode    => 644,
      notify  => Exec['nfs-update-nfs-exports'], # It should notify the service if the file changes
      require => Package['nfs-utils'],
      content => template("$module_name/exports.erb"),
    }

    exec { 'nfs-update-nfs-exports':
      refreshonly => true,
      command => '/usr/sbin/exportfs -a',
    }
    
    
  } else { # NFS clients

    package { $packages:
      ensure => installed,
    }

    service { $services:
      ensure  => running,
      enable  => true,
      require => Package[$packages],
    }
    
    # The template that uses the rules above
    file { ['/etc/auto.master']:
      mode    => 644,
      notify  => Service[$services], # It should notify the service if the file changes
      require => Package[$packages],
      content => template("$module_name/auto.master.erb"),
    }

    # The template that uses the rules above
    file { ['/etc/auto.vinasec.se']:
      mode    => 644,
      notify  => Service[$services], # It should notify the service if the file changes
      require => Package[$packages],
      content => template("$module_name/auto.vinasec.se.erb"),
    }
  }
}
