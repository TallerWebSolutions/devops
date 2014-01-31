  group { 'puppet':
    ensure => present
  }

  Exec { path  => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'] }

  File { owner => 0, group => 0, mode => 0644 }

  # Update O.S
  class {'apt':
    always_apt_update => true,
  }

  # Create Dir LXC
  file  { '/etc/lxc/auto':
    ensure  =>  directory,
    require =>  Package['lxc']
  }

  # Create Dir Bootstrap Openstack
  file  { '/home/vagrant.tmp':
    ensure  =>  directory,
    mode    =>  0755,
    owner   =>  vagrant,
    group   =>  vagrant
  }

  # Copy of user key for root
  exec  { 'copy-keys':
    command   =>  'cp -pR /home/vagrant/.ssh /root/',
    require   =>  Package['build-essential', 'vim', 'curl', 'wget', 'git-core', 'linux-image-generic-lts-raring', 'linux-headers-generic-lts-raring']
  }

  # Start Juju
  exec  { 'juju-init':
    command   =>  "su - vagrant -c \"juju init\"",
    path      =>  [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
    require   =>  Class['apt']
  }

  # Change environment Local
  exec  { 'juju-switch-local':
    command   =>  "su - vagrant -c \"juju switch local\"",
    path      =>  [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
    require   =>  File['/home/vagrant/.juju/environments.yaml'],
    timeout   =>  1200
  }

  # Bootstrap JuJu Local
  exec  { 'juju-bootstrap':
    command   =>  "su - vagrant -c \"sudo juju bootstrap\"",
    path      =>  [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
    require   =>  Exec['juju-switch-local']
  }

  # Change environment openstack
  exec  { 'juju-switch-openstack':
    command   =>  "su - vagrant -c \"juju switch openstack\"",
    path      =>  [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
    require   =>  [ File['/home/vagrant/.juju/environments.yaml'], Exec['juju-bootstrap'] ]
  }

  # Bootstrap JuJu Opentack
  exec  { 'juju-bootstrap-openstack':
    command   =>  "su - vagrant -c \"sudo juju bootstrap --constraints mem=2G\"",
    path      =>  [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
    require   =>  [ Exec['juju-switch-openstack'], Exec['start-sshuttle'] ],
    timeout   =>  2100
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

  # Add keys Root
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

  # Environment Settings
  file { '/home/vagrant/.juju/environments.yaml':
    content =>  template('environments.erb'),
    owner   =>  vagrant,
    group   =>  vagrant,
    mode    =>  0644,
    ensure  =>  present,
    require =>  [ Exec['copy-keys'], Class['apt'], Package[juju-local] ]
  }

  # Init Script Sshuttle
  file { '/etc/init.d/sshuttle':
    content =>  template('sshuttle.erb'),
    owner   =>  root,
    group   =>  root,
    mode    =>  0755,
    ensure  =>  present,
    require =>  Package[sshuttle]
  }

  exec { 'add-init-script-sshuttle':
    command =>  "/usr/bin/sudo /usr/sbin/update-rc.d sshuttle defaults 98 02",
    require =>  File['/etc/init.d/sshuttle']
  }

  exec { 'start-sshuttle':
    command =>  "/etc/init.d/sshuttle start",
    require =>  File['/etc/init.d/sshuttle']
  }

  # Install Packages
  package { [
    'build-essential',
    'vim',
    'curl',
    'git-core',
    'lxc',
    'linux-image-generic-lts-raring',
    'linux-headers-generic-lts-raring',
    'mongodb-server',
    'juju-local',
    'wget',
    'sshuttle'
    ]:
    ensure  => 'installed',
    require =>  Class[apt]
  }
