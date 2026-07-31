# @summary Configure clamonacc and optionally manage its package and service.
#
# Package-native service units are preferred. A caller may explicitly opt in
# to a module-rendered unit when its package does not provide one. Runtime
# directories and quarantine behavior are staged separately.
class clamav::clamonacc (
  Optional[String[1]] $package_name = undef,
  Optional[String[1]] $package_version = undef,
  Optional[Stdlib::Absolutepath] $binary_path = undef,
  Optional[Stdlib::Absolutepath] $config_path = undef,
  String[1] $config_owner = 'root',
  String[1] $config_group = 'root',
  Stdlib::Filemode $config_mode = '0644',
  String[1] $config_validate_cmd = '/usr/bin/env clamonacc --config-file % --version',
  Boolean $validate_config = true,
  Optional[String[1]] $service_name = undef,
  Clamav::Service_ensure $service_ensure = 'running',
  Boolean $service_enable = true,
  Boolean $manage_service_unit = false,
  Optional[Stdlib::Absolutepath] $service_unit_path = undef,
  Optional[String[1]] $daemon_service_name = undef,
  Clamav::Clamonacc_options $options = {},
  Optional[Array[Stdlib::Absolutepath, 1]] $include_paths = undef,
  Optional[Array[Stdlib::Absolutepath]] $exclude_paths = undef,
  Optional[Array[String[1]]] $exclude_usernames = undef,
  Optional[Stdlib::Absolutepath] $temporary_directory = undef,
  Optional[Stdlib::Absolutepath] $quarantine_path = undef,
  Optional[String[1]] $daemon_username = undef,
  Optional[Clamav::Clamonacc_listen_mode] $listen_mode = undef,
  Optional[Stdlib::Absolutepath] $local_socket = undef,
  Optional[Integer[1, 65535]] $tcp_port = undef,
  Optional[String[1]] $tcp_address = undef,
  Boolean $sort_options = true,
) {
  if $config_path == undef {
    fail('clamav::clamonacc requires config_path')
  }

  if $include_paths != undef {
    $_include_paths = $include_paths
  } elsif $options['OnAccessIncludePath'] != undef {
    $_include_paths = assert_type(
      Array[Stdlib::Absolutepath, 1],
      $options['OnAccessIncludePath'],
    )
  } else {
    fail('clamav::clamonacc requires at least one include path')
  }

  if $exclude_paths != undef {
    $_exclude_paths = $exclude_paths
  } elsif $options['OnAccessExcludePath'] != undef {
    $_exclude_paths = assert_type(
      Array[Stdlib::Absolutepath],
      $options['OnAccessExcludePath'],
    )
  } else {
    $_exclude_paths = []
  }

  if $exclude_usernames != undef {
    $_exclude_usernames = $exclude_usernames
  } elsif $options['OnAccessExcludeUname'] != undef {
    $_exclude_usernames = assert_type(
      Array[String[1]],
      $options['OnAccessExcludeUname'],
    )
  } else {
    $_exclude_usernames = []
  }

  if $temporary_directory != undef {
    $_temporary_directory = $temporary_directory
  } elsif $options['TemporaryDirectory'] != undef {
    $_temporary_directory = assert_type(
      Stdlib::Absolutepath,
      $options['TemporaryDirectory'],
    )
  } else {
    $_temporary_directory = undef
  }

  if $daemon_username != undef {
    $_daemon_username = $daemon_username
  } elsif $options['DaemonUsername'] != undef {
    $_daemon_username = assert_type(String[1], $options['DaemonUsername'])
  } elsif $options['User'] != undef {
    $_daemon_username = assert_type(String[1], $options['User'])
  } else {
    $_daemon_username = undef
  }

  if $listen_mode != undef {
    $_listen_mode = $listen_mode
  } elsif $options['ListenMode'] != undef {
    $_listen_mode = assert_type(
      Clamav::Clamonacc_listen_mode,
      $options['ListenMode'],
    )
  } else {
    $_listen_mode = 'LocalSocket'
  }

  if $local_socket != undef {
    $_local_socket = $local_socket
  } elsif $options['LocalSocket'] != undef {
    $_local_socket = assert_type(
      Stdlib::Absolutepath,
      $options['LocalSocket'],
    )
  } else {
    $_local_socket = undef
  }

  if $tcp_port != undef {
    $_tcp_port = $tcp_port
  } elsif $options['TCPSocket'] != undef {
    $_tcp_port = assert_type(
      Integer[1, 65535],
      $options['TCPSocket'],
    )
  } else {
    $_tcp_port = undef
  }

  if $tcp_address != undef {
    $_tcp_address = $tcp_address
  } elsif $options['TCPAddr'] != undef {
    $_tcp_address = assert_type(String[1], $options['TCPAddr'])
  } else {
    $_tcp_address = undef
  }

  if $_listen_mode == 'LocalSocket' and $_local_socket == undef {
    fail('clamav::clamonacc LocalSocket mode requires local_socket')
  }

  if $_listen_mode == 'TCPSocket' and $_tcp_port == undef {
    fail('clamav::clamonacc TCPSocket mode requires tcp_port')
  }

  if $_listen_mode == 'TCPSocket' and $_tcp_address == undef {
    fail('clamav::clamonacc TCPSocket mode requires tcp_address')
  }

  if $manage_service_unit and $service_name == undef {
    fail('clamav::clamonacc managed service unit requires service_name')
  }

  if $manage_service_unit and $binary_path == undef {
    fail('clamav::clamonacc managed service unit requires binary_path')
  }

  if $manage_service_unit and $service_unit_path == undef {
    fail('clamav::clamonacc managed service unit requires service_unit_path')
  }

  if $manage_service_unit and $daemon_service_name == undef {
    fail('clamav::clamonacc managed service unit requires daemon_service_name')
  }

  $reserved_options = [
    'ListenMode',
    'DaemonUsername',
    'LocalSocket',
    'TCPSocket',
    'TCPAddr',
    'User',
    'TemporaryDirectory',
    'OnAccessIncludePath',
    'OnAccessExcludePath',
    'OnAccessExcludeUname',
  ]

  $_extra_options = $options.filter |String $key, Clamav::Config_value $value| {
    ! ($key in $reserved_options) and $value != undef and $value != ''
  }

  $config_validate = $validate_config ? {
    true    => $config_validate_cmd,
    default => undef,
  }

  if $package_name != undef {
    $resolved_package_version = $package_version ? {
      undef   => 'installed',
      default => $package_version,
    }

    package { 'clamonacc':
      ensure => $resolved_package_version,
      name   => $package_name,
      before => File['clamonacc.conf'],
    }
  }

  file { 'clamonacc.conf':
    ensure       => file,
    path         => $config_path,
    owner        => $config_owner,
    group        => $config_group,
    mode         => $config_mode,
    validate_cmd => $config_validate,
    content      => epp('clamav/clamonacc.conf.epp', {
        'listen_mode'        => $_listen_mode,
        'local_socket'       => $_local_socket,
        'tcp_port'           => $_tcp_port,
        'tcp_address'        => $_tcp_address,
        'daemon_username'    => $_daemon_username,
        'temporary_directory' => $_temporary_directory,
        'include_paths'      => $_include_paths,
        'exclude_paths'      => $_exclude_paths,
        'exclude_usernames'  => $_exclude_usernames,
        'extra_options'      => $_extra_options,
        'sort_options'       => $sort_options,
    }),
  }

  if $manage_service_unit {
    $daemon_service_unit = $daemon_service_name ? {
      /[.]service$/ => $daemon_service_name,
      default       => "${daemon_service_name}.service",
    }

    file { 'clamonacc.service':
      ensure  => file,
      path    => $service_unit_path,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => epp('clamav/clamonacc.service.epp', {
          'binary_path'         => $binary_path,
          'config_path'         => $config_path,
          'daemon_service_unit' => $daemon_service_unit,
      }),
      notify  => Exec['clamonacc-systemd-daemon-reload'],
    }

    exec { 'clamonacc-systemd-daemon-reload':
      command     => '/usr/bin/systemctl daemon-reload',
      refreshonly => true,
      before      => Service['clamonacc'],
    }
  }

  if $service_name != undef {
    $service_subscriptions = $manage_service_unit ? {
      true    => [File['clamonacc.conf'], File['clamonacc.service']],
      default => File['clamonacc.conf'],
    }

    service { 'clamonacc':
      ensure     => $service_ensure,
      name       => $service_name,
      enable     => $service_enable,
      hasrestart => true,
      hasstatus  => true,
      subscribe  => $service_subscriptions,
    }

    if $package_name != undef {
      Package['clamonacc'] ~> Service['clamonacc']
    }
  }
}
