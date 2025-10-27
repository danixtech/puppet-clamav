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
  Hash $options       = $clamav::_clamd_options,
  Stdlib::Absolutepath $config_file = $clamav::clamd_config,
  String $service_name = $clamav::clamd_service,
  String $service_ensure = $clamav::clamd_service_ensure,
  Boolean $service_enable = $clamav::clamd_service_enable,
) {

  package { $clamav::clamd_package:
    ensure => $clamav::clamd_version,
    before => File[$config_file],
  }

  file { $config_file:
    ensure  => file,
    owner   => $clamav::params::user,
    group   => $clamav::params::group,
    mode    => '0644',
    content => epp('clamav/clamd.conf.epp', { 'options' => $options }),
    notify  => Service[$service_name],
  }

  service { $service_name:
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => [Package[$clamav::clamd_package], File[$config_file]],
  }
}
