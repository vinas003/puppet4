class openvpn {

  $packages = ['openvpn']

  # Iptables before openvpn to ensure firewall is running before we start openvpn
  $services = ['openvpn@server']

  package { $packages:
    ensure => installed,
    require => Package['epel-release'],
  }

  service { $services:
    ensure  => running,
    enable  => true,
    require => Package[$packages],
  }

  file_line { 'openvpn-ip_forwarding':
    path => '/etc/sysctl.conf',
    line => 'net.ipv4.ip_forward = 1',
  }
    
  file { ['/etc/openvpn/ccd']:
    ensure  => directory,
    require => Package[$openvpn::packages],
  }

  easy_file {
    [
     '/etc/openvpn/server.conf',
     '/etc/openvpn/ta.key',
     '/etc/openvpn/ca.crt',
     '/etc/openvpn/server.crt',
     '/etc/openvpn/server.key',
     '/etc/openvpn/dh.pem',
    ]:
    mode  => "600",
    owner => "openvpn",
  }


  # These are not a sensitive files so 644 on them
  easy_file { ['/etc/openvpn/ccd/client1']:
    mode => "644",
  }

  # These are not a sensitive files so 644 on them
  easy_file { ['/etc/openvpn/ccd/Tony1']:
    mode => "644",
  }

  # Run the openvpn fallback server on different port since we use a router
  if ($hostname != vpn2) {
    $openvpn_port = 1194
  } else {
    $openvpn_port = 1195

    exec { 'openvpn-selinux-allow-different-port':
      path    => ['/usr/bin', '/usr/sbin'], # Path to search for commands
      command => "semanage port -a -t openvpn_port_t -p udp $openvpn_port && touch /usr/share/openvpn-selinux-allow-different-port",
      notify  => Service[$services],   # It should notify the service httpd if the file changes
      require => Package[$packages],   # Before we copy the file these packages, directories must be installed
      creates => '/usr/share/openvpn-selinux-allow-different-port', # Puppet executes the command when this file NOT exists (so first time)
    }
  }

  # Needed the very first time we run puppet on a vpn server
  exec { 'openvpn-ensure_ip_forward':
    command => 'sysctl -w net.ipv4.ip_forward=1 && touch /usr/share/openvpn-ip_forward',
    creates => '/usr/share/openvpn-ip_forward',
    path    => ['/usr/bin', '/usr/sbin'], # Path to search for commands
    require => Service[$services],
  }  
}
