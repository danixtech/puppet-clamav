# @summary Set up freshclam config and service.
#
# @param config_owner
#   owner of the freshclam config file
# @param config_group
#   group that owns the freshclam config file
# @param mode
#   mode of the freshclam config file
# @param sort_options
#   for true, the options are sorted,
class clamav::freshclam(
  Hash $options             = $clamav::_freshclam_options,
  Stdlib::Absolutepath $config_file = $clamav::freshclam_config,
  Stdlib::Absolutepath $sysconfig_file = $clamav::freshclam_sysconfig,
  String $service_name      = $clamav::freshclam_service,
  String $service_ensure    = $clamav::freshclam_service_ensure,
  Boolean $service_enable   = $clamav::freshclam_service_enable,
  String $package_name      = $clamav::freshclam_package,
  String $package_version   = $clamav::freshclam_version,
  String $freshclam_delay   = '0',
) {

  $package_real      = pick($package_name,  $clamav::params::freshclam_package, 'clamav-freshclam')
  $package_version_real = pick($package_version, $clamav::params::freshclam_version, 'latest')
  $service_name_real = pick($service_name,  $clamav::params::freshclam_service, 'freshclam')
  $service_ensure_real = pick($service_ensure, $clamav::params::freshclam_service_ensure, 'running')
  $service_enable_real = pick($service_enable, $clamav::params::freshclam_service_enable, true)
  $sysconfig_file_real = pick($sysconfig_file, $clamav::params::freshclam_sysconfig, '/etc/default/freshclam')
  $delay_real = pick($freshclam_delay, '0')

  package { $package_real:
    ensure => $package_version_real,
    before => File[$config_file],
  }

  file { $config_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('clamav/freshclam.conf.epp', { 'options' => $options }),
    notify  => Service[$service_name_real],
  }

  file { $sysconfig_file_real:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('clamav/sysconfig/freshclam.epp', { 'freshclam_delay' => $delay_real }),
    notify  => Service[$service_name_real],
  }

  service { $service_name_real:
    ensure     => $service_ensure_real,
    enable     => $service_enable_real,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => [Package[$package_real], File[$config_file], File[$sysconfig_file_real]],
  }
}
