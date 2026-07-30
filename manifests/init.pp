# @summary Manage clamav
class clamav (
  Boolean $manage_user          = $clamav::params::manage_user,
  Boolean $manage_repo          = $clamav::params::manage_repo,
  Boolean $manage_clamd         = $clamav::params::manage_clamd,
  Boolean $manage_clamonacc     = $clamav::params::manage_clamonacc,
  Boolean $manage_freshclam     = $clamav::params::manage_freshclam,
  Boolean $manage_clamav_milter = $clamav::params::manage_clamav_milter,
  String $clamav_package        = $clamav::params::clamav_package,
  String $clamav_version        = $clamav::params::clamav_version,

  $user                         = $clamav::params::user,
  Optional[String] $comment     = $clamav::params::comment,
  $uid                          = $clamav::params::uid,
  $gid                          = $clamav::params::gid,
  Stdlib::Absolutepath $home    = $clamav::params::home,
  Stdlib::Absolutepath $shell   = $clamav::params::shell,
  $group                        = $clamav::params::group,
  $groups                       = $clamav::params::groups,

  String $clamd_package         = $clamav::params::clamd_package,
  String $clamd_version         = $clamav::params::clamd_version,
  Stdlib::Absolutepath $clamd_config = $clamav::params::clamd_config,
  String $clamd_service         = $clamav::params::clamd_service,
  $clamd_service_ensure         = $clamav::params::clamd_service_ensure,
  Boolean $clamd_service_enable = $clamav::params::clamd_service_enable,
  Optional[String[1]] $clamd_socket = $clamav::params::clamd_socket,
  Boolean $clamd_use_socket     = $clamav::params::clamd_use_socket,
  Hash $clamd_options           = $clamav::params::clamd_options,
  String[1] $clamd_config_validate_cmd = $clamav::params::clamd_config_validate_cmd,

  Optional[String[1]] $clamonacc_package = $clamav::params::clamonacc_package,
  Optional[String[1]] $clamonacc_package_version = $clamav::params::clamonacc_package_version,
  Optional[Stdlib::Absolutepath] $clamonacc_binary = $clamav::params::clamonacc_binary,
  Optional[Stdlib::Absolutepath] $clamonacc_config = $clamav::params::clamonacc_config,
  String[1] $clamonacc_config_owner = $clamav::params::clamonacc_config_owner,
  String[1] $clamonacc_config_group = $clamav::params::clamonacc_config_group,
  Stdlib::Filemode $clamonacc_config_mode = $clamav::params::clamonacc_config_mode,
  String[1] $clamonacc_config_validate_cmd = $clamav::params::clamonacc_config_validate_cmd,
  Optional[String[1]] $clamonacc_service = $clamav::params::clamonacc_service,
  Clamav::Service_ensure $clamonacc_service_ensure = $clamav::params::clamonacc_service_ensure,
  Boolean $clamonacc_service_enable = $clamav::params::clamonacc_service_enable,
  Clamav::Clamonacc_options $clamonacc_options = $clamav::params::clamonacc_options,
  Optional[Array[Stdlib::Absolutepath, 1]] $clamonacc_include_paths = $clamav::params::clamonacc_include_paths,
  Optional[Array[Stdlib::Absolutepath]] $clamonacc_exclude_paths = $clamav::params::clamonacc_exclude_paths,
  Optional[Array[String[1]]] $clamonacc_exclude_usernames = $clamav::params::clamonacc_exclude_usernames,
  Optional[Stdlib::Absolutepath] $clamonacc_temporary_directory = $clamav::params::clamonacc_temporary_directory,
  Optional[Stdlib::Absolutepath] $clamonacc_quarantine_path = $clamav::params::clamonacc_quarantine_path,
  Optional[String[1]] $clamonacc_daemon_username = $clamav::params::clamonacc_daemon_username,
  Optional[Clamav::Clamonacc_listen_mode] $clamonacc_listen_mode = $clamav::params::clamonacc_listen_mode,
  Optional[Stdlib::Absolutepath] $clamonacc_local_socket = $clamav::params::clamonacc_local_socket,
  Optional[Integer[1, 65535]] $clamonacc_tcp_port = $clamav::params::clamonacc_tcp_port,
  Optional[String[1]] $clamonacc_tcp_address = $clamav::params::clamonacc_tcp_address,
  Boolean $clamonacc_sort_options = $clamav::params::clamonacc_sort_options,

  $freshclam_package            = $clamav::params::freshclam_package,
  $freshclam_version            = $clamav::params::freshclam_version,
  Stdlib::Absolutepath $freshclam_config = $clamav::params::freshclam_config,
  $freshclam_service            = $clamav::params::freshclam_service,
  $freshclam_service_ensure     = $clamav::params::freshclam_service_ensure,
  Boolean $freshclam_service_enable = $clamav::params::freshclam_service_enable,
  Hash $freshclam_options       = $clamav::params::freshclam_options,
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig = $clamav::params::freshclam_sysconfig,
  Optional[String] $freshclam_delay = $clamav::params::freshclam_delay,
  String[1] $freshclam_config_validate_cmd = $clamav::params::freshclam_config_validate_cmd,

  Optional[String]               $clamav_milter_package        = $clamav::params::clamav_milter_package,
  Optional[String]               $clamav_milter_version        = $clamav::params::clamav_milter_version,
  Optional[Stdlib::Absolutepath] $clamav_milter_config         = $clamav::params::clamav_milter_config,
  Optional[String]               $clamav_milter_service        = $clamav::params::clamav_milter_service,
  String                         $clamav_milter_service_ensure = $clamav::params::clamav_milter_service_ensure,
  Boolean                        $clamav_milter_service_enable = $clamav::params::clamav_milter_service_enable,
  Hash                           $clamav_milter_options        = $clamav::params::clamav_milter_options,
  String[1]                      $milter_config_validate_cmd   = $clamav::params::milter_config_validate_cmd,
  Boolean                        $validate_configs             = true,

  Optional[Hash]                 $clamd_default_options        = undef,
  Optional[Hash]                 $freshclam_default_options    = undef,
  Optional[Hash]                 $milter_default_options       = undef,
) inherits clamav::params {
  if $clamd_use_socket and $clamd_socket == undef {
    fail('clamav::clamd_use_socket requires clamav::clamd_socket')
  }

  # clamd
  if $clamd_default_options {
    $_clamd_options = merge($clamd_default_options, $clamd_options)
  } else {
    $_clamd_options = merge($clamav::params::clamd_default_options, $clamd_options)
  }

  # freshclam
  if $freshclam_default_options {
    $_freshclam_options = merge($freshclam_default_options, $freshclam_options)
  } else {
    $_freshclam_options = merge($clamav::params::freshclam_default_options, $freshclam_options)
  }

  # clamav_milter
  if $milter_default_options {
    $_clamav_milter_options = merge($milter_default_options, $clamav_milter_options)
  } else {
    $_clamav_milter_options = merge($clamav::params::clamav_milter_default_options, $clamav_milter_options)
  }

  if $manage_repo { require 'epel' }

  if $manage_user {
    Anchor['clamav::begin']
    -> class { 'clamav::user': }
    -> Class['clamav::install']
  }

  if $manage_clamd {
    Class['clamav::install']
    -> class { 'clamav::clamd': }
    -> Anchor['clamav::end']
  }

  if $manage_clamonacc {
    $_clamonacc_local_socket = $clamonacc_local_socket ? {
      undef   => $_clamd_options['LocalSocket'],
      default => $clamonacc_local_socket,
    }

    Class['clamav::install']
    -> class { 'clamav::clamonacc':
      package_name        => $clamonacc_package,
      package_version     => $clamonacc_package_version,
      binary_path         => $clamonacc_binary,
      config_path         => $clamonacc_config,
      config_owner        => $clamonacc_config_owner,
      config_group        => $clamonacc_config_group,
      config_mode         => $clamonacc_config_mode,
      config_validate_cmd => $clamonacc_config_validate_cmd,
      validate_config     => $validate_configs,
      service_name        => $clamonacc_service,
      service_ensure      => $clamonacc_service_ensure,
      service_enable      => $clamonacc_service_enable,
      options             => $clamonacc_options,
      include_paths       => $clamonacc_include_paths,
      exclude_paths       => $clamonacc_exclude_paths,
      exclude_usernames   => $clamonacc_exclude_usernames,
      temporary_directory => $clamonacc_temporary_directory,
      quarantine_path     => $clamonacc_quarantine_path,
      daemon_username     => $clamonacc_daemon_username,
      listen_mode         => $clamonacc_listen_mode,
      local_socket        => $_clamonacc_local_socket,
      tcp_port            => $clamonacc_tcp_port,
      tcp_address         => $clamonacc_tcp_address,
      sort_options        => $clamonacc_sort_options,
    }
    -> Anchor['clamav::end']
  }

  if $manage_freshclam {
    Class['clamav::install']
    -> class { 'clamav::freshclam': }
    -> Anchor['clamav::end']
  }

  if $manage_clamav_milter {
    Class['clamav::install']
    -> class { 'clamav::clamav_milter': }
    -> Anchor['clamav::end']
  }

  anchor { 'clamav::begin': }
  -> class { 'clamav::install': }
  -> anchor { 'clamav::end': }
}
