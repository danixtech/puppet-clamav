# @summary Set up freshclam config and service.
#
# @param options
#   Hash of freshclam configuration options rendered into the config file.
#
# @param config_file
#   Absolute path to the freshclam.conf file to manage.
#
# @param service_name
#   Name of the freshclam system service.
#
# @param sort_options
#   Whether configuration options are rendered in sorted order.
class clamav::freshclam (
  Hash $options = $clamav::_freshclam_options,
  Stdlib::Absolutepath $config_file = $clamav::freshclam_config_real,
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig = $clamav::freshclam_sysconfig_real,
  Optional[Variant[Integer, String]] $freshclam_delay = $clamav::freshclam_delay_real,
  Optional[String] $service_name = $clamav::freshclam_service_real,
  String $service_ensure = $clamav::freshclam_service_ensure_real,
  Boolean $service_enable = $clamav::freshclam_service_enable_real,
  String $package_name   = $clamav::freshclam_package_real,
  String $package_version = $clamav::freshclam_version_real,
  Boolean $sort_options  = true,
) {
  package { $package_name:
    ensure => $package_version,
    before => File[$config_file],
  }

  if $freshclam_sysconfig {
    file { $freshclam_sysconfig:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => epp('clamav/sysconfig/freshclam.epp', { 'freshclam_delay' => $freshclam_delay }),
    }
  }

  if $facts['os']['name'] == 'Ubuntu' and $facts['os']['release']['major'] == '20.04' {
    file { '/var/run/clamav':
      ensure  => directory,
      owner   => $clamav::user_real,
      group   => $clamav::group_real,
      mode    => '0755',
      require => Package[$package_name],
      before  => File[$config_file],
    }
  }

  $config_notify = $service_name ? {
    undef   => undef,
    default => Service[$service_name],
  }

  file { $config_file:
    ensure  => file,
    owner   => $clamav::user_real,
    group   => $clamav::group_real,
    mode    => '0644',
    content => epp('clamav/freshclam.conf.epp', { 'options' => $options, 'sort_options' => $sort_options }),
    notify  => $config_notify,
  }

  if $service_name {
    $service_subscribe = $freshclam_sysconfig ? {
      undef   => [Package[$package_name], File[$config_file]],
      default => [Package[$package_name], File[$config_file], File[$freshclam_sysconfig]],
    }

    service { $service_name:
      ensure     => $service_ensure,
      enable     => $service_enable,
      hasrestart => true,
      hasstatus  => true,
      subscribe  => $service_subscribe,
    }
  }
}
