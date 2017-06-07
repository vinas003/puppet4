class mcollective {

#  $packages = ['mcollective', 'mcollective-puppet-agent', 'mcollective-shell-agent', 'mcollective-service-agent']
 # $managment_packages = ['mcollective-client', 'mcollective-puppet-client', 'mcollective-shell-client', 'mcollective-service-client']

  $services = ['mcollective']
  
  #package { $packages:
  #  ensure => installed,
  #}

  service { $services:
    ensure  => running,
    enable  => true,
 #   require => Package['mcollective'],
  }

  $mcollective_host      = "activemq-cert.greyhash.se"
  $mcollective_password  = "PASSWORD_HERE"
  
  # The managment nodes
  if ($hostname == 'root') or ($hostname == 'puppet') {

#    package { $managment_packages:
 #     ensure => installed,
  #  }
    
    file {
      [
       '/etc/mcollective.d/',
       '/etc/mcollective.d/credentials/',
       '/etc/mcollective.d/credentials/certs',
       '/etc/mcollective.d/credentials/private_keys'
      ]:
        mode   => "700",
        owner  => "root",
        group  => "root",
        ensure => directory,
        notify => Service[$services],
    }

    easy_file {
      [
       '/etc/mcollective.d/credentials/certs/mcollective-servers.pem',
       '/etc/mcollective.d/credentials/private_keys/vina.mco_key.pem',
       '/etc/mcollective.d/credentials/certs/vina.mco.pem',
       '/etc/puppetlabs/mcollective/client.cfg',
      ]:
    }    
    }

    file {
    [
    '/etc/mcollective/',
    '/etc/mcollective/ssl',
    '/etc/mcollective/ssl/clients',
    ]:
    mode   => "700",
    owner  => "root",
    group  => "root",
    ensure => directory,
    notify => Service[$services],
    }

  easy_file {
    [
     '/etc/mcollective/ssl/clients/vina.mco.pem',
     '/etc/mcollective/ssl/server_private.pem',
     '/etc/mcollective/ssl/server_public.pem',
     '/etc/puppetlabs/mcollective/server.cfg',
    ]:
  }    
  
  file { '/etc/mcollective/facts.yaml':
    owner    => "root",
    group    => "root",
    mode     => "400",
    # loglevel => debug, # Not needed any more
    content => inline_template('<%= scope.to_hash.reject { |k,v| !( k.is_a?(String) && v.is_a?(String) && k !~ /(uptime|free|timestamp)/ ) }.to_yaml %>'),
  }
}

