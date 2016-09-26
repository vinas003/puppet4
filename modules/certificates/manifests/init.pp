class certificates {
  
  # Define some standards for our Web-files
  define certificates-file($mode = 644, $owner = root) {
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
      content => template("$module_name/$filename.erb"), # the puppetmaster find this file in path-to-puppet-modules/web/templates/$filename.erb .erb since its a template
    }
  }  
  
  # Here we can use the standards we have defined for our web files
  certificates-file {
    [
     '/etc/pki/tls/certs/vinasec.se-chain.pem',
     '/etc/pki/tls/certs/vinasec.se.pem',
    ]:
  }

  certificates-file { '/etc/pki/tls/private/vinasec.se-key.pem':
    mode => 600,
  }

  # Create .key link for application compatibility
  file { '/etc/pki/tls/private/vinasec.se-key.key':
    ensure => link,
    target => '/etc/pki/tls/private/vinasec.se-key.pem',
  }
}

