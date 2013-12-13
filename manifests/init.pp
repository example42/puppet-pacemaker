#
# = Class: pacemaker
#
# This class installs and manages pacemaker
#
#
# == Parameters
#
# Refer to https://github.com/stdmod for official documentation
# on the stdmod parameters used
#
class pacemaker (

  $package_name              = $pacemaker::params::package_name,
  $package_ensure            = 'present',

  $service_name              = $pacemaker::params::service_name,
  $service_ensure            = 'running',
  $service_enable            = true,

  $config_file_path          = $pacemaker::params::config_file_path,
  $config_file_require       = 'Package[pacemaker]',
  $config_file_notify        = 'Service[pacemaker]',
  $config_file_source        = undef,
  $config_file_template      = undef,
  $config_file_content       = undef,
  $config_file_options_hash  = { } ,

  $config_dir_path           = $pacemaker::params::config_dir_path,
  $config_dir_source         = undef,
  $config_dir_purge          = false,
  $config_dir_recurse        = true,

  $conf_hash                 = undef,

  $dependency_class          = undef,
  $my_class                  = undef,

  $monitor_class             = undef,
  $monitor_options_hash      = { } ,

  $firewall_class            = undef,
  $firewall_options_hash     = { } ,

  $scope_hash_filter         = '(uptime.*|timestamp)',

  $tcp_port                  = undef,
  $udp_port                  = undef,

  ) inherits pacemaker::params {


  # Class variables validation and management

  validate_bool($service_enable)
  validate_bool($config_dir_recurse)
  validate_bool($config_dir_purge)
  if $config_file_options_hash { validate_hash($config_file_options_hash) }
  if $monitor_options_hash { validate_hash($monitor_options_hash) }
  if $firewall_options_hash { validate_hash($firewall_options_hash) }

  $config_file_owner          = $pacemaker::params::config_file_owner
  $config_file_group          = $pacemaker::params::config_file_group
  $config_file_mode           = $pacemaker::params::config_file_mode

  $manage_config_file_content = default_content($config_file_content, $config_file_template)

  $manage_config_file_notify  = $config_file_notify ? {
    'class_default' => 'Service[pacemaker]',
    ''              => undef,
    default         => $config_file_notify,
  }

  if $package_ensure == 'absent' {
    $manage_service_enable = undef
    $manage_service_ensure = stopped
    $config_dir_ensure = absent
    $config_file_ensure = absent
  } else {
    $manage_service_enable = $service_enable
    $manage_service_ensure = $service_ensure
    $config_dir_ensure = directory
    $config_file_ensure = present
  }


  # Dependency class

  if $pacemaker::dependency_class {
    include $pacemaker::dependency_class
  }


  # Resources managed

  if $pacemaker::package_name {
    package { 'pacemaker':
      ensure   => $pacemaker::package_ensure,
      name     => $pacemaker::package_name,
    }
  }

  if $pacemaker::config_file_path {
    file { 'pacemaker.conf':
      ensure  => $pacemaker::config_file_ensure,
      path    => $pacemaker::config_file_path,
      mode    => $pacemaker::config_file_mode,
      owner   => $pacemaker::config_file_owner,
      group   => $pacemaker::config_file_group,
      source  => $pacemaker::config_file_source,
      content => $pacemaker::manage_config_file_content,
      notify  => $pacemaker::manage_config_file_notify,
      require => $pacemaker::config_file_require,
    }
  }

  if $pacemaker::config_dir_source {
    file { 'pacemaker.dir':
      ensure  => $pacemaker::config_dir_ensure,
      path    => $pacemaker::config_dir_path,
      source  => $pacemaker::config_dir_source,
      recurse => $pacemaker::config_dir_recurse,
      purge   => $pacemaker::config_dir_purge,
      force   => $pacemaker::config_dir_purge,
      notify  => $pacemaker::manage_config_file_notify,
      require => $pacemaker::config_file_require,
    }
  }

  if $pacemaker::service_name {
    service { 'pacemaker':
      ensure     => $pacemaker::manage_service_ensure,
      name       => $pacemaker::service_name,
      enable     => $pacemaker::manage_service_enable,
    }
  }


  # Extra classes

  if $conf_hash {
    create_resources('pacemaker::conf', $conf_hash)
  }

  if $pacemaker::my_class {
    include $pacemaker::my_class
  }

  if $pacemaker::monitor_class {
    class { $pacemaker::monitor_class:
      options_hash => $pacemaker::monitor_options_hash,
      scope_hash   => {}, # TODO: Find a good way to inject class' scope
    }
  }

  if $pacemaker::firewall_class {
    class { $pacemaker::firewall_class:
      options_hash => $pacemaker::firewall_options_hash,
      scope_hash   => {},
    }
  }

}

