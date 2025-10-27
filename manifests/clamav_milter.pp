# @summary Set up clamav_milter config and service.
#
# @param sort_options
#   for true, the options are sorted,
#
class clamav::clamav_milter(
  Hash $options       = $clamav::_clamav_milter_options,
  Stdlib::Absolutepath $config_file = $clamav::clamav_milter_config,
  String $service_name = $clamav::clamav_milter_service,
  String $service_ensure = $clamav::clamav_milter_service_ensure,
  Boolean $service_enable = $clamav::clamav_milter_service_enable,
) {

  package { $clamav::clamav_milter_package:
    ensure => $clamav::clamav_milter_version,
    before => File[$config_file],
  }

  file { $config_file:
    ensure  => file,
    owner   => $clamav::params::user,
    group   => $clamav::params::group,
    mode    => '0644',
    content => epp('clamav/clamav-milter.conf.epp', { 'options' => $options }),
    notify  => Service[$service_name],
  }

  service { $service_name:
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => [Package[$clamav::clamav_milter_package], File[$config_file]],
  }
}
