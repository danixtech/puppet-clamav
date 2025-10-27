# @summary Set up clamd config and service.
#
# @param options
#   Hash of clamd configuration options rendered into the config file.
#
# @param config_file
#   Absolute path to the clamd.conf file to manage.
#
# @param service_name
#   Name of the clamd system service.
#
# @param service_ensure
#   Whether the clamd service should be running or stopped.
#
# @param service_enable
#   Whether the clamd service is enabled at boot.
#
class clamav::clamd(
  Hash $options            = $clamav::_clamd_options,
  Stdlib::Absolutepath $config_file = $clamav::clamd_config,
  String $service_name     = $clamav::clamd_service,
  String $service_ensure   = $clamav::clamd_service_ensure,
  Boolean $service_enable  = $clamav::clamd_service_enable,
  String $package_name     = $clamav::clamd_package,
  String $package_version  = $clamav::clamd_version,
) {

  $package_real       = pick($package_name,    $clamav::params::clamd_package, 'clamav-daemon')
  $package_version_real = pick($package_version, $clamav::params::clamd_version, 'latest')
  $service_name_real  = pick($service_name,    $clamav::params::clamd_service, 'clamav-daemon')
  $service_ensure_real = pick($service_ensure, $clamav::params::clamd_service_ensure, 'running')
  $service_enable_real = pick($service_enable, $clamav::params::clamd_service_enable, true)

  package { $package_real:
    ensure => $package_version_real,
    before => File[$config_file],
  }

  file { $config_file:
    ensure  => file,
    owner   => $clamav::params::user,
    group   => $clamav::params::group,
    mode    => '0644',
    content => epp('clamav/clamd.conf.epp', { 'options' => $options }),
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
