class mail {

  # Postfix package is included from the yum class
  $packages = ['dovecot', 'opendkim', 'opendmarc']
  
  $services = ['postfix', 'dovecot', 'opendkim', 'opendmarc']

  package { $packages:
    ensure => installed,
  }

  service { $services:
    ensure  => running,
    enable  => true,
    require => Package[$packages],
  }

  # Define some standards for our Web-files
  define mail-file($mode = 644, $owner = root) {
    # $name is the name of the object calling the this (the Web-file)
    # dirname is the path to te files directory, basename is the name of the file without the path
    $dirname  = dirname($name)
    $filename = basename($name)

    # Here we set the Web-files definitions, root:root 644 are default premissions
    file { "$module_name-$name":                         # Lets name this resource web-$name meaning prefix the filename with the puppet class name
      path    => $name,                                  # The filepath
      mode    => $mode,                                  # Set permissions to 644
      owner   => $owner,                                 # Set owner to root
      group   => $owner,                                 # Set group owner to root
      notify  => Service[$mail::services],            # It should notify the service httpd if the file changes
      require => [                                       # Before we copy the file these packages, directories must be installed
                  Package[$mail::packages],
                  Class['certificates'],
                  File['/etc/opendkim/keys/vinasec.se'],
                 ],
      content => template("$module_name/$filename.erb"), # The puppetmaster find this file in path-to-puppet-modules/web/templates/$filename.erb .erb since its a template
    }
  }

  # Dir for the opendkim keys
  file { '/etc/opendkim/keys/vinasec.se':
    mode    => 700,
    owner   => opendkim,
    group   => opendkim,
    ensure  => directory,
    require => Package[$packages],
  }
  
  mail-file {
    [
     '/etc/postfix/main.cf',
     '/etc/postfix/master.cf',
     '/etc/dovecot/dovecot.conf',
     '/etc/dovecot/conf.d/10-auth.conf',
     '/etc/dovecot/conf.d/10-mail.conf',
     '/etc/dovecot/conf.d/10-master.conf',
     '/etc/dovecot/conf.d/10-ssl.conf',
     '/etc/opendkim.conf',
     '/etc/opendmarc.conf',
    ]:
      owner => root,
  }

  mail-file {
    [
     '/etc/opendkim/KeyTable',
     '/etc/opendkim/SigningTable',
     '/etc/opendkim/TrustedHosts',
     '/etc/opendkim/keys/vinasec.se/default.txt',
     '/etc/opendkim/keys/vinasec.se/default.private',
    ]:
      mode  => 600,
      owner => opendkim,
  }

#  mailalias { ['vina', 'vinasec.se']:
 #   recipient => 'root@vinasec.se',
  # }
}
