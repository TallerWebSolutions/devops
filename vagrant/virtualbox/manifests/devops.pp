  group { 'puppet':
    ensure => present
  }

  Exec { path  => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'] }

  File { owner => 0, group => 0, mode => 0644 }

  # Update O.S
  class {'apt':
    always_apt_update => true,
    require   =>  Exec['repo-juju']
  }

  # Add repository packages JuJu
  exec { 'repo-juju':
    command   =>  'add-apt-repository ppa:juju/stable',
    path      => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/']
  }

  # Copy of user key for root
  exec  { 'copy-keys':
    command   =>  'cp -pR /home/vagrant/.ssh /root/',
    require   =>  Package['build-essential', 'vim', 'curl', 'git-core', 'juju-local', 'linux-image-generic-lts-raring', 'linux-headers-generic-lts-raring']
  }

  # Start Juju
  exec  { 'juju-init':
    command   =>  "sudo su -c \"juju init\"",
    path      => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
    require   =>  Class['apt']
  }

  # Change environment Local
  exec  { 'juju-switch-local':
    command   => "sudo su -c \"juju switch local\"",
    path      => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
    require   => Exec['juju-init']
  }

  # Bootstrap JuJu
  exec  { 'juju-bootstrap':
    command   => "sudo su -c \"juju bootstrap\"",
    path      => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
    require   => Exec['juju-switch-local']
  }

  # Loads module of App the Kernel
  exec  { 'apparmor_parser':
    command   =>  "sudo su -c \"apparmor_parser -R /etc/apparmor.d/usr.bin.lxc-start\" && sudo su -c \"ln -s /etc/apparmor.d/usr.bin.lxc-start /etc/apparmor.d/disable \"",
    path      =>  [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
    require   =>  Exec['juju-switch-local', 'disable-firewall']
  }

  # Disable Firewall
  exec  { 'disable-firewall':
    command   =>  "sudo su -c \"ufw disable\"",
    path      =>  [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  }

  file { '/root/.ssh/id_rsa':
    owner   =>  root,
    group   =>  root,
    mode    =>  0600,
    ensure  =>  present,
    require =>  Exec['copy-keys']
  }

  file { '/root/.ssh/id_rsa.pub':
    owner   =>  root,
    group   =>  root,
    mode    =>  0600,
    ensure  =>  present,
    require =>  Exec['copy-keys']
  }

  file { '/root/.ssh/config':
    owner   =>  root,
    group   =>  root,
    mode    =>  0644,
    ensure  =>  present,
    require =>  Exec['copy-keys']
  } 

  package { [
    'build-essential',
    'vim',
    'curl',
    'git-core',
    'juju-local',
    'linux-image-generic-lts-raring',
    'linux-headers-generic-lts-raring'
    ]:
    ensure  => 'installed',
    require =>  Class[apt]
  }

