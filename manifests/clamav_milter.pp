# @summary Set up clamav_milter config and service.
#
# @param options
#   Hash of clamav-milter configuration options rendered into the config file.
#
# @param config_file
#   Absolute path to the clamav-milter.conf file to manage.
#
# @param service_name
#   Name of the clamav-milter system service.
#
# @param sort_options
#   Whether configuration options are rendered in sorted order.
#
class clamav::clamav_milter (
  Hash $options           = $clamav::_clamav_milter_options,
  Stdlib::Absolutepath $config_file = $clamav::clamav_milter_config_real,
  String $service_name    = $clamav::clamav_milter_service_real,
  String $service_ensure  = $clamav::clamav_milter_service_ensure_real,
  Boolean $service_enable = $clamav::clamav_milter_service_enable_real,
  String $package_name    = $clamav::clamav_milter_package_real,
  String $package_version = $clamav::clamav_milter_version_real,
  Boolean $sort_options   = true,
) {
  package { $package_name:
    ensure => $package_version,
    before => File[$config_file],
  }

  file { $config_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('clamav/clamav-milter.conf.epp', { 'options' => $options, 'sort_options' => $sort_options }),
    notify  => Service[$service_name],
  }

  service { $service_name:
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => [Package[$package_name], File[$config_file]],
  }
}
