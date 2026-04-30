# manifests/init.pp
# @summary Manage ClamAV
class clamav (
  # Core flags
  Boolean $manage_user          = $clamav::params::manage_user,
  Boolean $manage_repo          = $clamav::params::manage_repo,
  Boolean $manage_clamd         = $clamav::params::manage_clamd,
  Boolean $manage_freshclam     = $clamav::params::manage_freshclam,
  Boolean $manage_clamav_milter = $clamav::params::manage_clamav_milter,

  # OS-specific defaults from module Hiera (APL)
  Hash $os_clamd_defaults       = {},
  Hash $os_freshclam_defaults   = {},
  Hash $os_milter_defaults      = {},

  # Packages
  Optional[String] $clamav_package        = undef,
  Optional[String] $clamd_package         = undef,
  Optional[String] $freshclam_package     = undef,
  Optional[String] $clamav_milter_package = undef,

  # Versions
  Optional[String] $clamav_version        = undef,
  Optional[String] $clamd_version         = undef,
  Optional[String] $freshclam_version     = undef,
  Optional[String] $clamav_milter_version = undef,

  # User account
  Optional[String] $user  = undef,
  Optional[String] $group = undef,
  Optional[Integer] $uid  = undef,
  Optional[Integer] $gid  = undef,
  Optional[Stdlib::Absolutepath] $home  = undef,
  Optional[Stdlib::Absolutepath] $shell = undef,
  Optional[String] $comment = undef,
  Optional[Array[String]] $groups = undef,

  # Configs
  Optional[Stdlib::Absolutepath] $clamd_config         = undef,
  Optional[Stdlib::Absolutepath] $freshclam_config     = undef,
  Optional[Stdlib::Absolutepath] $clamav_milter_config = undef,
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig  = undef,
  Optional[Integer] $freshclam_delay                  = undef,

  # Services
  Optional[String] $clamd_service             = undef,
  Optional[String] $freshclam_service         = undef,
  Optional[String] $clamav_milter_service    = undef,
  Optional[String] $clamd_service_ensure     = undef,
  Optional[String] $freshclam_service_ensure = undef,
  Optional[String] $clamav_milter_service_ensure = undef,
  Optional[Boolean] $clamd_service_enable         = undef,
  Optional[Boolean] $freshclam_service_enable     = undef,
  Optional[Boolean] $clamav_milter_service_enable = undef,

  # Options
  Optional[Hash] $clamd_options        = {},
  Optional[Hash] $freshclam_options    = {},
  Optional[Hash] $clamav_milter_options = {},
  Optional[Hash] $clamd_default_options     = undef,
  Optional[Hash] $freshclam_default_options = undef,
  Optional[Hash] $milter_default_options    = undef,
) inherits clamav::params {

  ###########################
  # Safe parameter defaults #
  ###########################

  # Packages
  $clamav_package_real        = pick($clamav_package, $clamav_package_default)
  $clamd_package_real         = pick($clamd_package,  $clamd_package_default)
  $freshclam_package_real     = pick($freshclam_package, $freshclam_package_default)
  $clamav_milter_package_real = pick($clamav_milter_package, $clamav_milter_package_default)

  # Versions
  $clamav_version_real        = pick($clamav_version, $clamav_version_default, 'latest')
  $clamd_version_real         = pick($clamd_version, $clamd_version_default, 'latest')
  $freshclam_version_real     = pick($freshclam_version, $freshclam_version_default, 'latest')
  $clamav_milter_version_real = pick($clamav_milter_version, $clamav_milter_version_default, 'latest')

  # Services
  $clamd_service_real        = pick($clamd_service, $clamd_service_default, 'clamd')
  $clamd_service_ensure_real = pick($clamd_service_ensure, $clamd_service_ensure_default, 'running')
  $clamd_service_enable_real = pick($clamd_service_enable, $clamd_service_enable_default, true)
  $clamd_use_socket_real = pick($clamd_use_socket, false)
  $clamd_socket_real     = pick($clamd_socket, $clamd_socket_default)

  $freshclam_service_real        = pick($freshclam_service, $freshclam_service_default, 'freshclam')
  $freshclam_service_ensure_real = pick($freshclam_service_ensure, $freshclam_service_ensure_default, 'running')
  $freshclam_service_enable_real = pick($freshclam_service_enable, $freshclam_service_enable_default, true)

  $clamav_milter_service_real        = pick($clamav_milter_service, $clamav_milter_service_default, 'clamav-milter')
  $clamav_milter_service_ensure_real = pick($clamav_milter_service_ensure, $clamav_milter_service_ensure_default, 'running')
  $clamav_milter_service_enable_real = pick($clamav_milter_service_enable, $clamav_milter_service_enable_default, true)

  # User account
  $user_real    = pick($user,  $user_default, 'clamav')
  $group_real   = pick($group, $group_default, 'clamav')
  $uid_real     = pick($uid,   $uid_default, 496)
  $gid_real     = pick($gid,   $gid_default, 496)
  $home_real    = pick($home,  $home_default, '/var/lib/clamav')
  $shell_real   = pick($shell, $shell_default, '/sbin/false')
  $comment_real = pick($comment, $comment_default, 'ClamAV user')
  $groups_real  = pick($groups, $groups_default, [])

  # Config paths
  $clamd_config_real         = pick($clamd_config, $clamd_config_default, '/etc/clamav/clamd.conf')
  $freshclam_config_real     = pick($freshclam_config, $freshclam_config_default, '/etc/clamav/freshclam.conf')
  $clamav_milter_config_real = pick($clamav_milter_config, $clamav_milter_config_default, '/etc/clamav/clamav-milter.conf')
  $freshclam_sysconfig_real  = pick($freshclam_sysconfig, $freshclam_sysconfig_default, '/etc/default/freshclam')
  $freshclam_delay_real      = pick($freshclam_delay, $freshclam_delay_default, '0')

  ############################
  # Merge options with defaults
  ############################
  $_clamd_options = merge(
    $clamd_default_options,
    pick($clamd_options, {})
  )

  $_freshclam_options = merge(
    $freshclam_default_options,
    pick($freshclam_options, {})
  )

  $_clamav_milter_options = merge(
    $clamav_milter_default_options,
    pick($clamav_milter_options, {})
  )

  ############################
  # Manage repo
  ############################
  if $manage_repo { require 'epel' }

  ############################
  # Manage user
  ############################
  if $manage_user {
    anchor { 'clamav::begin': }
      -> class { 'clamav::user': }
      -> class { 'clamav::install': }
      -> anchor { 'clamav::end': }
  }

  ############################
  # Manage services
  ############################
  if $manage_clamd {
    Class['clamav::install']
      -> class { 'clamav::clamd':
           config_file     => $clamd_config_real,
           service_name    => $clamd_service_real,
           service_ensure  => $clamd_service_ensure_real,
           service_enable  => $clamd_service_enable_real,
           package_name    => $clamd_package_real,
           package_version => $clamd_version_real,
         }
      -> Anchor['clamav::end']
  }

  if $manage_freshclam {
    Class['clamav::install']
      -> class { 'clamav::freshclam':
           config_file         => $freshclam_config_real,
           freshclam_sysconfig => $freshclam_sysconfig_real,
           freshclam_delay     => $freshclam_delay_real,
           service_name        => $freshclam_service_real,
           service_ensure      => $freshclam_service_ensure_real,
           service_enable      => $freshclam_service_enable_real,
           package_name        => $freshclam_package_real,
           package_version     => $freshclam_version_real,
         }
      -> Anchor['clamav::end']
  }

  if $manage_clamav_milter {
    Class['clamav::install']
      -> class { 'clamav::clamav_milter':
           config_file     => $clamav_milter_config_real,
           service_name    => $clamav_milter_service_real,
           service_ensure  => $clamav_milter_service_ensure_real,
           service_enable  => $clamav_milter_service_enable_real,
           package_name    => $clamav_milter_package_real,
           package_version => $clamav_milter_version_real,
         }
      -> Anchor['clamav::end']
  }

  # Ensure anchors exist if user management is skipped
  anchor { 'clamav::begin': }
    -> class { 'clamav::install': }
    -> anchor { 'clamav::end': }
}
