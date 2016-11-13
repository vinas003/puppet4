class iptables {

  $packages = ['iptables-services']
  $services = ['iptables']
  
  package { $packages:
    ensure => installed,
  }

  service { $services:
    ensure  => running,
    enable  => true,
    require => Package[$packages],
  }

  $nat_rule = '-A POSTROUTING -s 10.9.0.0/24 -o eth0 -j MASQUERADE'

  if ($hostname == 'ssh') {
    $rules = [
              '# Drop ssh bruteforces for 12 hours in hope they will go away',
              '-A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSHBRUTE -j ACCEPT',
              '-A INPUT -p tcp --dport 22 -m recent --update --seconds 18000 --hitcount 20 --rttl --name SSHBRUTE -j DROP',
             ]
  } elsif ($hostname =~ /^ssh/) { # This will match ssh2, ssh3 etc but not ssh since its matched above
    $rules = [
              '# Drop ssh bruteforces for 12 hours in hope they will go away',
              '-A INPUT -p tcp --dport 9538 -m state --state NEW -m recent --set --name SSHBRUTE -j ACCEPT',
              '-A INPUT -p tcp --dport 9538 -m recent --update --seconds 18000 --hitcount 20 --rttl --name SSHBRUTE -j DROP',
              ]
  } elsif ($hostname == 'vpn') {
    $rules = [
              '# Allow incoming vpn connections',
              '-A INPUT -p udp --dport 1194 -j ACCEPT',
              '# Allow ip forwarding to and from openvpn interface to eth0',
              '-A FORWARD -i tun0 -o eth0 -j ACCEPT',
              '-A FORWARD -i eth0 -o tun0 -j ACCEPT',
              ]
  } elsif ($hostname =~ /^vpn/) { # This will match vpn2, vpn3 etc but not vpn since its matched above
    $rules = [
              '# Allow incoming vpn connections',
              '-A INPUT -p udp --dport 1195 -j ACCEPT',
              '# Allow ip forwarding to and from openvpn interface to eth0',
              '-A FORWARD -i tun0 -o eth0 -j ACCEPT',
              '-A FORWARD -i eth0 -o tun0 -j ACCEPT',
              ]
  } elsif ($hostname =~ /^mail/) {
    $rules = [
              '# Allow incoming mail connections',
              '-A INPUT -p tcp -m multiport --dports 25,993,995,143,110 -j ACCEPT',
             ]
  } elsif ($hostname =~ /^web/) {
    $rules = [
              '# Allow incoming web connections',
              '-A INPUT -p tcp -m multiport --dports 80,443,8000 -j ACCEPT',
             ]
  } elsif ($hostname =~ /^dns/) {
    $rules = [
              '# Allow incoming dns connections',
              '-A INPUT -p tcp --dport 53 -j ACCEPT',
              '-A INPUT -p udp --dport 53 -j ACCEPT',
             ]
  } elsif ($hostname =~ /^puppet/) {
    $rules = [
              '# Allow incoming web connections',
              '-A INPUT -p tcp -s 10.8.0.0/24 -m multiport --dports 61616,8140 -j ACCEPT',
              '-A INPUT -p tcp -s 10.10.0.0/24 -m multiport --dports 61616,8140 -j ACCEPT',
              '# Allow vpn clients to access foreman',
              '-A INPUT -p tcp -s 10.9.0.0/24 --dport 443 -j ACCEPT',
              ]
  } elsif ($hostname =~ /^nfs/) {
    $rules = [
              '# Allow incoming nfs connections',
              '-A INPUT -p tcp -s 10.8.0.0/24 -m multiport --dports 111,2049,662,892,32803 -j ACCEPT',
              '-A INPUT -p tcp -s 10.9.0.0/24 -m multiport --dports 111,2049,662,892,32803 -j ACCEPT',
              '-A INPUT -p tcp -s 10.10.0.0/24 -m multiport --dports 111,2049,662,892,32803 -j ACCEPT',
              '-A INPUT -p udp -s 10.8.0.0/24 -m multiport --dports 111,2049,662,892,32769 -j ACCEPT',
              '-A INPUT -p udp -s 10.9.0.0/24 -m multiport --dports 111,2049,662,892,32769 -j ACCEPT',
              '-A INPUT -p udp -s 10.10.0.0/24 -m multiport --dports 111,2049,662,892,32769 -j ACCEPT',
              ]

  } else { # everone else who dont need special iptables rules
    $rules = [ ]
  }
    
  # The template that uses the rules above
  file { ["/etc/sysconfig/iptables"]:
    mode    => "640",
    notify  => Service[$services], # It should notify the service if the file changes
    require => Package[$packages],
    content => epp("$module_name/iptables.epp"),
  }
}
