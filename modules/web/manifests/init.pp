class web {

  # Which packages are required for this class
  # at is required by mod_pagespeed, certbot is required since we use a lets encrypt ssl cert
  # mod_security for some standard security
  $packages = ['httpd', 'at', 'certbot', 'mod_ssl', 'mod_security', 'mod_security_crs']

  # The services needed for the website
  $services = ['httpd', 'atd']
  
  # Directory which mod_pagespeed keep its cache, will be mount to tmpfs (RAM)
  $modpagespeed_cache_dir = '/var/cache/mod_pagespeed'

  # Directory where for files for the website are
  $website_dir = '/www'

  # Need this for pathing should work
  $website_dir_dirname  = dirname($website_dir)  # parent dir to $website_dir
  $website_dir_basename = basename($website_dir) # name of the $website_dir without parent dirs
  
  # Install the packages, we update all packages using the puppet class yum
  package { $packages:
    ensure  => installed,
    require => Package['epel-release'], # We require epel-release for some packages
  }

  # Define the services
  service { $services:
    ensure  => running,            # We want them running
    enable  => true,               # They should start at boot
    require => Package[$packages], # They requires the packages to be installed
  }

  # Mount the mod_pagespeed cache in tmpsfs (RAM)
  mount { 'web-mount-pagespeed-cache-tmpfs':   # Lets name this resource web-$name meaning prefix the mount with the puppet class name
    name     => $modpagespeed_cache_dir,       # Directory to mount
    atboot   => true,                          # Mount at boot
    ensure   => mounted,                       # We want it to be mounted all times
    device   => 'tmpfs',                       # Mount the directory in RAM
    fstype   => 'tmpfs',                       # Mount the directory in RAM
    notify   => Service[$services],              # It should notify the service httpd if the mount changes
    require  =>                                # Need mod_pagespeed to be installed and mountpoint to exists
    [
     File["$modpagespeed_cache_dir"],
     Exec['install-mod-pagespeed'],
    ],
    remounts => true,                          # We allow it to be remounted, its ok since httpd would then restart
    # Set the options to max size 120MB since we have set pagespeed to have max 100MB size
    # Max Inodes to 505K since we have set pagespeed to have 500k max inodes
    # Standards security settings nodev, nosuid and mode=0700
    # Set the owner and group to apache (httpd)
    options  => 'rw,size=120M,nr_inodes=505k,nodev,nosuid,uid=48,gid=48,mode=0700',
  }


  class { certificates:
  }
  
  Exec { 
      cwd     => '/',                       # Current working directory for the command
      user    => "root",                     # Which user to run the command as
      path    => ['/usr/bin', '/usr/sbin'], # Path to search for commands
      notify  => Service[$web::services],   # It should notify the service httpd if the file changes
      require => Package[$web::packages],   # Before we copy the file these packages, directories must be installed
      creates => $creates,                  # Puppet executes the command when this file NOT exists (so first time)
  }
  

  # Cache dir for mod_pagespeed
  file { "$modpagespeed_cache_dir":
    mode  => "700",
    ensure => directory,
    owner => apache,
    require => Package[$packages], # They requires the packages to be installed
  }

  # Dir for the website files, owner centos so apache cant edit the files
  file { "$website_dir":
    mode    => "755",
    owner   => centos,
    ensure => directory,
    require => Exec['clone-website'],
  }
  
  # Here we can use the standards we have defined for our web files
  easy_file {
    [
     '/etc/httpd/conf/httpd.conf',
     '/etc/httpd/conf.d/ssl.conf',
     '/etc/httpd/conf.d/pagespeed.conf',
     '/etc/httpd/conf.d/vinasec.se.conf',
     '/etc/httpd/conf.d/vinasec.se_ssl.conf',
     '/etc/httpd/modsecurity.d/activated_rules/rules-01.conf',
     '/etc/httpd/modsecurity.d/modsecurity_crs_10_config.conf',
     '/etc/cron.d/vina-website-daily', # cron file which daily does git pull on the website
    ]:
  }

  # If fails then we have a copy of the rpm in this module under templates for manual installation
  exec { 'install-mod-pagespeed':
    command => 'curl https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_x86_64.rpm -o mod-pagespeed-stable_current_x86_64.rpm && rpm -U mod-pagespeed-stable_current_x86_64.rpm && rm -f mod-pagespeed-stable_current_x86_64.rpm',
    creates => '/usr/lib64/httpd/modules/mod_pagespeed.so',
  }

  # Clone the the website, we update it with cron, chmown to centos so httpd wont own the files
  exec { 'clone-website': 
    command => "mkdir -p $website_dir_dirname && cd $website_dir_dirname && git clone https://github.com/vinas003/vinasec.se.git $website_dir_basename && chown -R centos:centos $website_dir",
    creates => "$website_dir/index.shtml",
  }
  
  # Set httpd read only selinux context (httpd_sys_content_t) on the webfiles so httpd can read them
  exec { 'set-selinux-context-www': 
    command => "semanage fcontext -a -t httpd_sys_content_t \"$website_dir(/.*)?\" && restorecon -R -v $website_dir && touch $website_dir/selinux-context-on-www",
    creates => "$website_dir/selinux-context-on-www",
    require => Exec['clone-website'],
  }

  # Set httpd cache selinux context (httpd_cache_t) on mod_pagespeed cache dir so httpd can store cache there
  exec { 'set-selinux-context-www-cache': 
    command => "semanage fcontext -a -t httpd_cache_t \"$modpagespeed_cache_dir(/.*)?\" && restorecon -R -v $modpagespeed_cache_dir && touch $modpagespeed_cache_dir/selinux-context-on-www-cache",
    creates => "$modpagespeed_cache_dir/selinux-context-on-www-cache",
    require => Mount['web-mount-pagespeed-cache-tmpfs'],
  }
  
  # Disable cgi for httpd since we dont use it
  exec { 'set-httpd-selinux-httpd_enable_cgi':
    command => 'setsebool -P httpd_enable_cgi 0 && touch /usr/share/selinux-httpd_enable_cgi',
    creates => '/usr/share/selinux-httpd_enable_cgi',
  }

  # Disable builtin_scripting for httpd since we dont use it
  exec { 'set-httpd-selinux-httpd_builtin_scripting':
    command => 'setsebool -P httpd_builtin_scripting 0 && touch /usr/share/selinux-httpd_builtin_scripting',
    creates => '/usr/share/selinux-httpd_builtin_scripting',
  }

  # The above selinux commands does not check the selinux booleans every run
  # Which is bad, we could do somthing like below but thats bad as well
  
  # exec { 'set-httpd-selinux-httpd_enable_cgi':
  # command => 'semanage boolean -l | grep httpd_enable_cgi | grep "(on" && setsebool -P httpd_enable_cgi 0 || exit 0',
  # cwd     => '/root',                       # Current working directory for the command
  # path    => ['/usr/bin', '/usr/sbin'], # Path to search for commands
  # creates => '/usr/share/selinux-httpd_enable_cgi',
  # }

}

