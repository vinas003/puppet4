class puppet {

  $packages = ['puppet-agent']
  $services = ['puppet']

  $splay = fqdn_rand(30)
  
  package { $packages:
    ensure => installed,
  }
    
  # Not disable puppet on the puppetmaster server
  if !($hostname == 'puppet') {

    service { $services:
      ensure  => stopped,
      enable => false,
      require => Package[$packages],
     }

     file {
       [
        '/etc/cron.d/vina-puppet',
       ]:
	content => template("${module_name}/vina-puppet.erb"),
     }

     # On the puppet master / foreman
  } else {
    
    package { 'foreman-installer':
      ensure => installed,
    }
    
    service { ['puppetserver', 'foreman-proxy']:
      ensure  => running,
      enable => true,
      require => [
                  Package[$packages],
                  Package['foreman-installer'],
                 ]
    }
    
    file {
      [
       '/etc/puppetlabs/puppet/autosign.conf',
      ]:
        owner   => "foreman-proxy",
        group   => "puppet",
        mode    => "664",
        notify  => Service['foreman-proxy', 'puppetserver'], # We do not have puppet service running, we use cron for it
	content => template("${module_name}/autosign.conf.erb"),
    }

    file {
      [
       '/etc/foreman/plugins/foreman_default_hostgroup.yaml',
      ]:
        owner   => "foreman-proxy",
        group   => "puppet",
        mode    => "664",
        notify  => Service['foreman-proxy', 'puppetserver'], # We do not have puppet service running, we use cron for it
	content => template("${module_name}/foreman_default_hostgroup.yaml.erb"),
    }


  }
}
