# @summary Define the typed, package-neutral clamonacc public contract.
#
# This class deliberately manages no package, configuration, service, runtime
# directory, or quarantine resources. Those capabilities are staged in later
# clamonacc issues.
class clamav::clamonacc (
  Optional[String[1]] $package_name = undef,
  Optional[String[1]] $package_version = undef,
  Optional[Stdlib::Absolutepath] $binary_path = undef,
  Optional[Stdlib::Absolutepath] $config_path = undef,
  Optional[String[1]] $service_name = undef,
  Clamav::Service_ensure $service_ensure = 'running',
  Boolean $service_enable = true,
  Clamav::Clamonacc_options $options = {},
  Optional[Array[Stdlib::Absolutepath, 1]] $include_paths = undef,
  Optional[Array[Stdlib::Absolutepath]] $exclude_paths = undef,
  Optional[Array[String[1]]] $exclude_usernames = undef,
  Optional[Stdlib::Absolutepath] $temporary_directory = undef,
  Optional[Stdlib::Absolutepath] $quarantine_path = undef,
  Optional[String[1]] $daemon_username = undef,
  Optional[Clamav::Clamonacc_listen_mode] $listen_mode = undef,
) {
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

  # #16 will consume this normalized hash. Explicit typed parameters take
  # precedence over compatibility values in clamonacc_options.
  $_options = merge($options, {
      'ListenMode'              => $_listen_mode,
      'DaemonUsername'         => $_daemon_username,
      'OnAccessIncludePath'    => $_include_paths,
      'OnAccessExcludePath'    => $_exclude_paths,
      'OnAccessExcludeUname'   => $_exclude_usernames,
      'TemporaryDirectory'     => $_temporary_directory,
  })
}
