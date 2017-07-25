class certificates {
  
  
  # Here we can use the standards we have defined for our web files
  easy_file {
    [
     '/etc/pki/tls/certs/vinasec.se-chain.pem',
     '/etc/pki/tls/certs/vinasec.se-fullchain.pem',
     '/etc/pki/tls/certs/vinasec.se.pem',
    ]:
  }

  easy_file { '/etc/pki/tls/private/vinasec.se-key.pem':
    mode => "600",
  }

  # Create .key link for application compatibility
  file { '/etc/pki/tls/private/vinasec.se-key.key':
    ensure => link,
    target => '/etc/pki/tls/private/vinasec.se-key.pem',
  }
}

