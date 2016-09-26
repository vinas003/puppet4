class yum {

  # Set splay time for running yum update
  $splay = fqdn_rand(30)

  # Basic packages all servers should have
  $packages = [
               'deltarpm',
               'screen',
               'lsof',
               'nload',
               'iotop',
               'nmap-ncat',
               'nmap',
               'htop',
               'sendmail',
               'git',
               'postfix',
               'emacs',
               'rpm-build',
               'mlocate',
               'bind-utils',
               'tcpdump',
               'nano',
               'setools-console',
               'bash-completion-extras',
	       'yum-plugin-priorities',
              ]
	      
  package { ['epel-release']:
    ensure => installed,
  }

  Exec { "puppet_repo":
    path    => "/usr/sbin:/usr/bin",
    command => "rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm",
    creates => "/etc/yum.repos.d/puppetlabs-pc1.repo",
  }

  package { $packages:
    ensure  => installed,
    require => [ Package['epel-release'], Exec['puppet_repo'], ],
  }

  easy_file {
    [
     '/etc/yum.repos.d/CentOS-Base.repo',
     '/etc/yum.repos.d/epel.repo',
     '/etc/yum.repos.d/puppetlabs.repo',
     '/etc/yum/pluginconf.d/fastestmirror.conf',
     '/etc/cron.d/vina-yum-daily',
    ]:
  }
}
