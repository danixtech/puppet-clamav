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
class clamav::freshclam(
  Hash $options = $clamav::_freshclam_options,
  Stdlib::Absolutepath $config_file = $clamav::freshclam_config,
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig = $clamav::freshclam_sysconfig,
  Optional[Integer] $freshclam_delay = $clamav::freshclam_delay,
  String $service_name   = $clamav::freshclam_service,
  String $service_ensure = $clamav::freshclam_service_ensure,
  Boolean $service_enable = $clamav::freshclam_service_enable,
  String $package_name   = $clamav::freshclam_package,
  String $package_version = $clamav::freshclam_version,
) {

  package { $package_name:
    ensure => $package_version,
    before => File[$config_file],
  }

  file { $config_file:
    ensure  => file,
    owner   => $clamav::user_real,
    group   => $clamav::group_real,
    mode    => '0644',
    content => epp('clamav/freshclam.conf.epp', { 'options' => $options }),
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
