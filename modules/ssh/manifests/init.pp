class ssh {

  $packages = ['openssh']
  $services = ['sshd']
  
  package { $packages:
    ensure => installed,
  }

  service { $services:
    ensure  => running,
    enable  => true,
    require => Package[$packages],
  }

  # Run the ssh fallback server on different port since we use a router
  if ($hostname != ssh) {
    $ssh_port = 22
  } else {
    $ssh_port = 9538
    
    exec { 'ssh-selinux-allow-different-port':
      path    => ['/usr/bin', '/usr/sbin'], # Path to search for commands
      command => "semanage port -a -t ssh_port_t -p tcp $ssh_port && touch /usr/share/ssh-selinux-allow-different-port",
      notify  => Service[$services],   # It should notify the service httpd if the file changes
      require => Package[$packages],   # Before we copy the file these packages, directories must be installed
      creates => '/usr/share/ssh-selinux-allow-different-port', # Puppet executes the command when this file NOT exists (so first time)
    }      
  }
  
  easy_file { ['/etc/ssh/sshd_config']:
    mode => "640",
  }

  easy_file { ['/home/centos/.ssh/authorized_keys']:
    owner => "centos",
  }

  exec { 'generate ed25519 hostkey':
    path    => ['/usr/bin', '/usr/sbin'], # Path to search for commands
    command => 'rm /etc/ssh/ssh_host_ed25519_key && ssh-keygen -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key && touch /etc/ssh/ssh_host_ed25519_key-generated',
    notify  => Service[$services],   # It should notify the service httpd if the file changes
    require => Package[$packages],   # Before we copy the file these packages, directories must be installed
    creates => '/etc/ssh/ssh_host_ed25519_key-generated', # Puppet executes the command when this file NOT exists (so first time)
  }  
}
