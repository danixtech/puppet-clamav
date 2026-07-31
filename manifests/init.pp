# @summary Manage clamav
class clamav (
  Boolean $manage_user          = $clamav::params::manage_user,
  Boolean $manage_repo          = $clamav::params::manage_repo,
  Boolean $manage_clamd         = $clamav::params::manage_clamd,
  Boolean $manage_clamonacc     = $clamav::params::manage_clamonacc,
  Boolean $manage_freshclam     = $clamav::params::manage_freshclam,
  Boolean $manage_clamav_milter = $clamav::params::manage_clamav_milter,
  String $clamav_package        = $clamav::params::clamav_package,
  Clamav::Package_ensure $clamav_version = $clamav::params::clamav_version,

  $user                         = $clamav::params::user,
  Optional[String] $comment     = $clamav::params::comment,
  $uid                          = $clamav::params::uid,
  $gid                          = $clamav::params::gid,
  Stdlib::Absolutepath $home    = $clamav::params::home,
  Stdlib::Absolutepath $shell   = $clamav::params::shell,
  $group                        = $clamav::params::group,
  $groups                       = $clamav::params::groups,

  String $clamd_package         = $clamav::params::clamd_package,
  Clamav::Package_ensure $clamd_version = $clamav::params::clamd_version,
  Stdlib::Absolutepath $clamd_config = $clamav::params::clamd_config,
  String $clamd_service         = $clamav::params::clamd_service,
  Clamav::Service_ensure $clamd_service_ensure = $clamav::params::clamd_service_ensure,
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
  Boolean $clamonacc_manage_service_unit = $clamav::params::clamonacc_manage_service_unit,
  Optional[Stdlib::Absolutepath] $clamonacc_service_unit_path = $clamav::params::clamonacc_service_unit_path,
  Clamav::Clamonacc_options $clamonacc_options = $clamav::params::clamonacc_options,
  Optional[Array[Stdlib::Absolutepath, 1]] $clamonacc_include_paths = $clamav::params::clamonacc_include_paths,
  Optional[Array[Stdlib::Absolutepath]] $clamonacc_exclude_paths = $clamav::params::clamonacc_exclude_paths,
  Optional[Array[String[1]]] $clamonacc_exclude_usernames = $clamav::params::clamonacc_exclude_usernames,
  Optional[Stdlib::Absolutepath] $clamonacc_temporary_directory = $clamav::params::clamonacc_temporary_directory,
  Boolean $clamonacc_manage_temporary_directory = $clamav::params::clamonacc_manage_temporary_directory,
  String[1] $clamonacc_temporary_directory_owner = $clamav::params::clamonacc_temporary_directory_owner,
  String[1] $clamonacc_temporary_directory_group = $clamav::params::clamonacc_temporary_directory_group,
  Stdlib::Filemode $clamonacc_temporary_directory_mode = $clamav::params::clamonacc_temporary_directory_mode,
  Optional[Stdlib::Absolutepath] $clamonacc_quarantine_path = $clamav::params::clamonacc_quarantine_path,
  Boolean $clamonacc_manage_quarantine = $clamav::params::clamonacc_manage_quarantine,
  String[1] $clamonacc_quarantine_owner = $clamav::params::clamonacc_quarantine_owner,
  String[1] $clamonacc_quarantine_group = $clamav::params::clamonacc_quarantine_group,
  Stdlib::Filemode $clamonacc_quarantine_mode = $clamav::params::clamonacc_quarantine_mode,
  Optional[String[1]] $clamonacc_daemon_username = $clamav::params::clamonacc_daemon_username,
  Optional[Clamav::Clamonacc_listen_mode] $clamonacc_listen_mode = $clamav::params::clamonacc_listen_mode,
  Optional[Stdlib::Absolutepath] $clamonacc_local_socket = $clamav::params::clamonacc_local_socket,
  Optional[Integer[1, 65535]] $clamonacc_tcp_port = $clamav::params::clamonacc_tcp_port,
  Optional[String[1]] $clamonacc_tcp_address = $clamav::params::clamonacc_tcp_address,
  Boolean $clamonacc_sort_options = $clamav::params::clamonacc_sort_options,

  $freshclam_package            = $clamav::params::freshclam_package,
  Clamav::Package_ensure $freshclam_version = $clamav::params::freshclam_version,
  Stdlib::Absolutepath $freshclam_config = $clamav::params::freshclam_config,
  $freshclam_service            = $clamav::params::freshclam_service,
  Clamav::Service_ensure $freshclam_service_ensure = $clamav::params::freshclam_service_ensure,
  Boolean $freshclam_service_enable = $clamav::params::freshclam_service_enable,
  Hash $freshclam_options       = $clamav::params::freshclam_options,
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig = $clamav::params::freshclam_sysconfig,
  Optional[String] $freshclam_delay = $clamav::params::freshclam_delay,
  String[1] $freshclam_config_validate_cmd = $clamav::params::freshclam_config_validate_cmd,

  Optional[String]               $clamav_milter_package        = $clamav::params::clamav_milter_package,
  Optional[Clamav::Package_ensure] $clamav_milter_version = $clamav::params::clamav_milter_version,
  Optional[Stdlib::Absolutepath] $clamav_milter_config         = $clamav::params::clamav_milter_config,
  Optional[String]               $clamav_milter_service        = $clamav::params::clamav_milter_service,
  Clamav::Service_ensure         $clamav_milter_service_ensure = $clamav::params::clamav_milter_service_ensure,
  Boolean                        $clamav_milter_service_enable = $clamav::params::clamav_milter_service_enable,
  Hash                           $clamav_milter_options        = $clamav::params::clamav_milter_options,
  String[1]                      $milter_config_validate_cmd   = $clamav::params::milter_config_validate_cmd,
  Boolean                        $validate_configs             = true,

  Optional[Hash]                 $clamd_default_options        = undef,
  Optional[Hash]                 $freshclam_default_options    = undef,
  Optional[Hash]                 $milter_default_options       = undef,
  Array[Clamav::Directory_definition] $managed_directories      = [],
  Boolean                        $manage_selinux               = false,
  Array[Clamav::Selinux_context] $selinux_file_contexts         = [],
  Array[String[1]]               $selinux_booleans              = [],
  Boolean                        $manage_apparmor              = false,
  Array[Clamav::Apparmor_profile] $apparmor_profiles            = [],
) inherits clamav::params {
  # Directory ownership is explicit and bounded: no parents are inferred and
  # package-managed defaults remain untouched unless listed by the caller.
  $managed_directories.each |Clamav::Directory_definition $directory| {
    file { "clamav managed directory ${directory['path']}":
      ensure => directory,
      path   => $directory['path'],
      owner  => $directory['owner'],
      group  => $directory['group'],
      mode   => $directory['mode'],
    }
  }

  if $manage_selinux {
    class { 'clamav::selinux':
      file_contexts => $selinux_file_contexts,
      booleans      => $selinux_booleans,
    }
  }

  if $manage_apparmor {
    class { 'clamav::apparmor':
      profiles => $apparmor_profiles,
    }
  }

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
      manage_service_unit => $clamonacc_manage_service_unit,
      service_unit_path   => $clamonacc_service_unit_path,
      daemon_service_name => $clamd_service,
      options             => $clamonacc_options,
      include_paths       => $clamonacc_include_paths,
      exclude_paths       => $clamonacc_exclude_paths,
      exclude_usernames   => $clamonacc_exclude_usernames,
      temporary_directory => $clamonacc_temporary_directory,
      manage_temporary_directory => $clamonacc_manage_temporary_directory,
      temporary_directory_owner => $clamonacc_temporary_directory_owner,
      temporary_directory_group => $clamonacc_temporary_directory_group,
      temporary_directory_mode => $clamonacc_temporary_directory_mode,
      quarantine_path     => $clamonacc_quarantine_path,
      manage_quarantine   => $clamonacc_manage_quarantine,
      quarantine_owner    => $clamonacc_quarantine_owner,
      quarantine_group    => $clamonacc_quarantine_group,
      quarantine_mode     => $clamonacc_quarantine_mode,
      daemon_username     => $clamonacc_daemon_username,
      listen_mode         => $clamonacc_listen_mode,
      local_socket        => $_clamonacc_local_socket,
      tcp_port            => $clamonacc_tcp_port,
      tcp_address         => $clamonacc_tcp_address,
      sort_options        => $clamonacc_sort_options,
    }
    -> Anchor['clamav::end']

    if $manage_clamd {
      Class['clamav::clamd'] -> Class['clamav::clamonacc']
    }
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
