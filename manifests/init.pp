# manifests/init.pp
# @summary Manage ClamAV
class clamav (
  # Core flags
  Boolean $manage_user          = $clamav::params::manage_user,
  Boolean $manage_repo          = $clamav::params::manage_repo,
  Boolean $manage_clamd         = $clamav::params::manage_clamd,
  Boolean $manage_freshclam     = $clamav::params::manage_freshclam,
  Boolean $manage_clamav_milter = $clamav::params::manage_clamav_milter,

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
  Optional[String[1]] $user             = undef,
  Optional[String[1]] $group            = undef,
  Optional[Integer] $uid                = undef,
  Optional[Integer] $gid                = undef,
  Optional[Stdlib::Absolutepath] $home  = undef,
  Optional[Stdlib::Absolutepath] $shell = undef,
  Optional[String] $comment             = undef,
  Optional[Array[String]] $groups       = undef,

  # Configs
  Optional[Stdlib::Absolutepath] $clamd_config         = undef,
  Optional[Stdlib::Absolutepath] $freshclam_config     = undef,
  Optional[Stdlib::Absolutepath] $clamav_milter_config = undef,
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig  = undef,
  Optional[Integer] $freshclam_delay                   = undef,

  # Services
  Optional[String] $clamd_service                 = undef,
  Optional[String[1]] $clamd_socket               = undef,
  Optional[String] $freshclam_service             = undef,
  Optional[String] $clamav_milter_service         = undef,
  Optional[String] $clamd_service_ensure          = undef,
  Optional[String] $freshclam_service_ensure      = undef,
  Optional[String] $clamav_milter_service_ensure  = undef,
  Optional[Boolean] $clamd_service_enable         = undef,
  Optional[Boolean] $clamd_use_socket             = undef,
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
  $clamav_package_real        = pick($clamav_package, $clamav::params::clamav_package_default)
  $clamd_package_real         = pick($clamd_package,  $clamav::params::clamd_package_default)
  $freshclam_package_real     = pick($freshclam_package, $clamav::params::freshclam_package_default)
  $clamav_milter_package_real = pick($clamav_milter_package, $clamav::params::clamav_milter_package_default)

  # Versions
  $clamav_version_real        = pick($clamav_version, $clamav::params::clamav_version_default, 'latest')
  $clamd_version_real         = pick($clamd_version, $clamav::params::clamd_version_default, 'latest')
  $freshclam_version_real     = pick($freshclam_version, $clamav::params::freshclam_version_default, 'latest')
  $clamav_milter_version_real = pick($clamav_milter_version, $clamav::params::clamav_milter_version_default, 'latest')

  # Services
  $clamd_service_real        = pick($clamd_service, $clamav::params::clamd_service_default, 'clamd')
  $clamd_service_ensure_real = pick($clamd_service_ensure, $clamav::params::clamd_service_ensure_default, 'running')
  $clamd_service_enable_real = pick($clamd_service_enable, $clamav::params::clamd_service_enable_default, true)
  $clamd_use_socket_real     = pick($clamd_use_socket, $clamav::params::clamd_use_socket)

  # Conditional definition of clamd_socket_real
  if $clamd_use_socket_real {
    $clamd_socket_real = pick($clamd_socket,$clamav::params::clamd_socket_default)
  } else {
    $clamd_socket_real = undef
  }

  $freshclam_service_real        = pick($freshclam_service, $clamav::params::freshclam_service_default, 'freshclam')
  $freshclam_service_ensure_real = pick($freshclam_service_ensure, $clamav::params::freshclam_service_ensure_default, 'running')
  $freshclam_service_enable_real = pick($freshclam_service_enable, $clamav::params::freshclam_service_enable_default, true)

  $clamav_milter_service_real        = pick($clamav_milter_service, $clamav::params::clamav_milter_service_default, 'clamav-milter')
  $clamav_milter_service_ensure_real = pick($clamav_milter_service_ensure, $clamav::params::clamav_milter_service_ensure_default, 'running')
  $clamav_milter_service_enable_real = pick($clamav_milter_service_enable, $clamav::params::clamav_milter_service_enable_default, true)

  # User account
  $user_real    = pick($user,  $clamav::params::user_default)
  $group_real   = pick($group, $clamav::params::group_default)
  $uid_real     = $uid ? { undef => $clamav::params::uid_default, default => $uid }
  $gid_real     = $gid ? { undef => $clamav::params::gid_default, default => $gid }
  $home_real    = pick($home,  $clamav::params::home_default)
  $shell_real   = pick($shell, $clamav::params::shell_default)
  $comment_real = pick($comment, $clamav::params::comment_default, 'ClamAV user')
  $groups_real  = $groups ? { undef => $clamav::params::groups_default, default => $groups }

  # Config paths
  $clamd_config_real         = pick($clamd_config, $clamav::params::clamd_config_default, '/etc/clamav/clamd.conf')
  $freshclam_config_real     = pick($freshclam_config, $clamav::params::freshclam_config_default, '/etc/clamav/freshclam.conf')
  $clamav_milter_config_real = pick($clamav_milter_config, $clamav::params::clamav_milter_config_default, '/etc/clamav/clamav-milter.conf')
  $freshclam_sysconfig_real  = pick($freshclam_sysconfig, $clamav::params::freshclam_sysconfig_default, '/etc/default/freshclam')
  $freshclam_delay_real      = pick($freshclam_delay, $clamav::params::freshclam_delay_default, '0')

  ############################
  # Merge options with defaults
  ############################
  $clamd_defaults_real = $clamd_default_options ? {
    undef   => $clamav::params::clamd_default_options,
    default => merge(
      $clamav::params::clamd_default_options,
      $clamd_default_options,
    ),
  }

  $freshclam_defaults_real = $freshclam_default_options ? {
    undef   => $clamav::params::freshclam_default_options,
    default => merge(
      $clamav::params::freshclam_default_options,
      $freshclam_default_options,
    ),
  }

  $_clamd_options = merge(
    $clamd_defaults_real,
    $clamd_options,
  )

  $_freshclam_options = merge(
    $freshclam_defaults_real,
    $freshclam_options,
  )

  $_clamav_milter_options = merge(
    pick($milter_default_options, $clamav::params::clamav_milter_default_options),
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
