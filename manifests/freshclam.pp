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
#
class clamav::freshclam(
  Hash $options       = $clamav::_freshclam_options,
  Stdlib::Absolutepath $config_file = $clamav::freshclam_config,
  Optional[Stdlib::Absolutepath] $sysconfig_file = $clamav::freshclam_sysconfig,
  String $service_name = $clamav::freshclam_service,
  String $service_ensure = $clamav::freshclam_service_ensure,
  Boolean $service_enable = $clamav::freshclam_service_enable,
) {

  if $clamav::freshclam_package {
    package { $clamav::freshclam_package:
      ensure => $clamav::freshclam_version,
      before => File[$config_file],
    }
  }

  file { $config_file:
    ensure  => file,
    owner   => $options['DatabaseOwner'] ? { undef => $clamav::params::user, default => $options['DatabaseOwner'] },
    group   => $clamav::params::group,
    mode    => '0644',
    content => epp('clamav/freshclam.conf.epp', { 'options' => $options }),
    notify  => $service_name ? { undef => undef, default => Service[$service_name] },
  }

  if $sysconfig_file {
    file { $sysconfig_file:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => epp('clamav/sysconfig/freshclam.epp', { 'freshclam_delay' => $clamav::freshclam_delay }),
      notify  => $service_name ? { undef => undef, default => Service[$service_name] },
    }
  }

  if $service_name {
    $subscribe_resources = [$config_file]
    if $sysconfig_file { $subscribe_resources += [$sysconfig_file] }

    service { $service_name:
      ensure    => $service_ensure,
      enable    => $service_enable,
      hasrestart => true,
      hasstatus  => true,
      subscribe => $subscribe_resources,
    }
  }
}
