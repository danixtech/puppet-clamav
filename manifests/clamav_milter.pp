# @summary Set up clamav_milter config and service.
#
# @param sort_options
#   for true, the options are sorted,
#
class clamav::clamav_milter(
  Hash $options           = $clamav::_clamav_milter_options,
  Stdlib::Absolutepath $config_file = $clamav::clamav_milter_config,
  String $service_name    = $clamav::clamav_milter_service,
  String $service_ensure  = $clamav::clamav_milter_service_ensure,
  Boolean $service_enable = $clamav::clamav_milter_service_enable,
  String $package_name    = $clamav::clamav_milter_package,
  String $package_version = $clamav::clamav_milter_version,
) {

  $package_real      = pick($package_name,  $clamav::params::clamav_milter_package, 'clamav-milter')
  $package_version_real = pick($package_version, $clamav::params::clamav_milter_version, 'latest')
  $service_name_real = pick($service_name,  $clamav::params::clamav_milter_service, 'clamav-milter')
  $service_ensure_real = pick($service_ensure, $clamav::params::clamav_milter_service_ensure, 'running')
  $service_enable_real = pick($service_enable, $clamav::params::clamav_milter_service_enable, true)

  package { $package_real:
    ensure => $package_version_real,
    before => File[$config_file],
  }

  file { $config_file:
    ensure  => file,
    owner   => $clamav::params::user,
    group   => $clamav::params::group,
    mode    => '0644',
    content => epp('clamav/clamav_milter.conf.epp', { 'options' => $options }),
    notify  => Service[$service_name_real],
  }

  service { $service_name_real:
    ensure     => $service_ensure_real,
    enable     => $service_enable_real,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => [Package[$package_real], File[$config_file]],
  }
}

