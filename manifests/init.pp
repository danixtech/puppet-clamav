# manifests/init.pp
# @summary Manage ClamAV packages, services, and configuration
class clamav (
  # User parameters
  Optional[String] $user  = undef,
  Optional[String] $group = undef,
  Optional[Integer] $uid   = undef,
  Optional[Integer] $gid   = undef,
  Optional[Stdlib::Absolutepath] $home  = undef,
  Optional[Stdlib::Absolutepath] $shell = undef,

  # Package versions (optional)
  Optional[String] $clamav_package        = undef,
  Optional[String] $clamav_version        = undef,
  Optional[String] $clamd_package         = undef,
  Optional[String] $clamd_version         = undef,
  Optional[String] $freshclam_package     = undef,
  Optional[String] $freshclam_version     = undef,
  Optional[String] $clamav_milter_package = undef,
  Optional[String] $clamav_milter_version = undef,

  # Service parameters
  Optional[String]  $clamd_service              = undef,
  Optional[String]  $clamd_service_ensure       = undef,
  Optional[Boolean] $clamd_service_enable       = undef,
  Optional[String]  $freshclam_service          = undef,
  Optional[String]  $freshclam_service_ensure   = undef,
  Optional[Boolean] $freshclam_service_enable   = undef,
  Optional[String]  $clamav_milter_service      = undef,
  Optional[String]  $clamav_milter_service_ensure = undef,
  Optional[Boolean] $clamav_milter_service_enable = undef,

  # Config paths
  Optional[Stdlib::Absolutepath] $clamd_config       = undef,
  Optional[Stdlib::Absolutepath] $freshclam_config   = undef,
  Optional[Stdlib::Absolutepath] $clamav_milter_config = undef,
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig = undef,
  Optional[String]               $freshclam_delay    = undef,

  # Config options
  Optional[Hash] $clamd_options        = {},
  Optional[Hash] $freshclam_options    = {},
  Optional[Hash] $clamav_milter_options = {},

  # Internal defaults
  Optional[Hash] $clamd_default_options      = undef,
  Optional[Hash] $freshclam_default_options  = undef,
  Optional[Hash] $milter_default_options     = undef,

  # Control flags
  Boolean $manage_user          = $clamav::params::manage_user,
  Boolean $manage_repo          = $clamav::params::manage_repo,
  Boolean $manage_clamd         = $clamav::params::manage_clamd,
  Boolean $manage_freshclam     = $clamav::params::manage_freshclam,
  Boolean $manage_clamav_milter = $clamav::params::manage_clamav_milter,
) inherits clamav::params {

  # Merge real values with params defaults
  $user_real    = pick($user, $clamav::params::user)
  $group_real   = pick($group, $clamav::params::group)
  $uid_real     = pick($uid, $clamav::params::uid)
  $gid_real     = pick($gid, $clamav::params::gid)
  $home_real    = pick($home, $clamav::params::home)
  $shell_real   = pick($shell, $clamav::params::shell)

  $clamav_package_real        = pick($clamav_package, $clamav::params::clamav_package)
  $clamd_package_real         = pick($clamd_package, $clamav::params::clamd_package)
  $freshclam_package_real     = pick($freshclam_package, $clamav::params::freshclam_package)
  $clamav_milter_package_real = pick($clamav_milter_package, $clamav::params::clamav_milter_package)

  $clamd_service_real              = pick($clamd_service, $clamav::params::clamd_service)
  $clamd_service_ensure_real       = pick($clamd_service_ensure, $clamav::params::clamd_service_ensure)
  $clamd_service_enable_real       = pick($clamd_service_enable, $clamav::params::clamd_service_enable)
  $freshclam_service_real          = pick($freshclam_service, $clamav::params::freshclam_service)
  $freshclam_service_ensure_real   = pick($freshclam_service_ensure, $clamav::params::freshclam_service_ensure)
  $freshclam_service_enable_real   = pick($freshclam_service_enable, $clamav::params::freshclam_service_enable)
  $clamav_milter_service_ensure_real = pick($clamav_milter_service_ensure, $clamav::params::clamav_milter_service_ensure)
  $clamav_milter_service_enable_real = pick($clamav_milter_service_enable, $clamav::params::clamav_milter_service_enable)

  $clamd_config_real       = pick($clamd_config, $clamav::params::clamd_config)
  $freshclam_config_real   = pick($freshclam_config, $clamav::params::freshclam_config)
  $clamav_milter_config_real = pick($clamav_milter_config, $clamav::params::clamav_milter_config)
  $freshclam_sysconfig_real   = pick($freshclam_sysconfig, $clamav::params::freshclam_sysconfig)
  $freshclam_delay_real       = pick($freshclam_delay, $clamav::params::freshclam_delay)

  # Merge default and user options
  $_clamd_options = merge(
    pick($clamd_default_options, $clamav::params::clamd_default_options),
    $clamd_options
  )
  $_freshclam_options = merge(
    pick($freshclam_default_options, $clamav::params::freshclam_default_options),
    $freshclam_options
  )
  $_clamav_milter_options = merge(
    pick($milter_default_options, $clamav::params::clamav_milter_options),
    $clamav_milter_options
  )

  # Optional: manage EPEL repo on RedHat
  if $manage_repo { require 'epel' }

  # Optional: manage clamav user
  if $manage_user {
    class { 'clamav::user':
      user  => $user_real,
      group => $group_real,
      uid   => $uid_real,
      gid   => $gid_real,
      home  => $home_real,
      shell => $shell_real,
    }
  }

  # Include submodules
  if $manage_clamd {
    class { 'clamav::clamd':
      sort_options => true,
    }
  }
  if $manage_freshclam {
    class { 'clamav::freshclam':
      sort_options => true,
    }
  }
  if $manage_clamav_milter {
    class { 'clamav::clamav_milter':
      sort_options => true,
    }
  }

}
