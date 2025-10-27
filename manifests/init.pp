# @summary Manage ClamAV installation, configuration, and services
class clamav (
  # Boolean flags
  Boolean $manage_user          = $clamav::params::manage_user,
  Boolean $manage_repo          = $clamav::params::manage_repo,
  Boolean $manage_clamd         = $clamav::params::manage_clamd,
  Boolean $manage_freshclam     = $clamav::params::manage_freshclam,
  Boolean $manage_clamav_milter = $clamav::params::manage_clamav_milter,

  # Packages & versions
  String $clamav_package        = $clamav::params::clamav_package,
  String $clamav_version        = $clamav::params::clamav_version,
  String $clamd_package         = $clamav::params::clamd_package,
  String $clamd_version         = $clamav::params::clamd_version,
  String $freshclam_package     = $clamav::params::freshclam_package,
  String $freshclam_version     = $clamav::params::freshclam_version,
  Optional[String] $clamav_milter_package        = $clamav::params::clamav_milter_package,
  Optional[String] $clamav_milter_version        = $clamav::params::clamav_milter_version,

  # Users
  String $user                   = $clamav::params::user,
  Optional[String] $comment      = $clamav::params::comment,
  Integer $uid                   = $clamav::params::uid,
  Integer $gid                   = $clamav::params::gid,
  Stdlib::Absolutepath $home    = $clamav::params::home,
  Stdlib::Absolutepath $shell   = $clamav::params::shell,
  String $group                  = $clamav::params::group,
  Optional[Array[String]] $groups = $clamav::params::groups,

  # Config paths
  Stdlib::Absolutepath $clamd_config        = $clamav::params::clamd_config,
  Stdlib::Absolutepath $freshclam_config    = $clamav::params::freshclam_config,
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig = $clamav::params::freshclam_sysconfig,
  Optional[String] $freshclam_delay         = $clamav::params::freshclam_delay,
  Optional[Stdlib::Absolutepath] $clamav_milter_config = $clamav::params::clamav_milter_config,

  # Services
  String  $clamd_service                 = $clamav::params::clamd_service,
  String  $clamd_service_ensure          = $clamav::params::clamd_service_ensure,
  Boolean $clamd_service_enable          = $clamav::params::clamd_service_enable,
  String  $freshclam_service             = $clamav::params::freshclam_service,
  String  $freshclam_service_ensure      = $clamav::params::freshclam_service_ensure,
  Boolean $freshclam_service_enable      = $clamav::params::freshclam_service_enable,
  Optional[String] $clamav_milter_service        = $clamav::params::clamav_milter_service,
  String  $clamav_milter_service_ensure = $clamav::params::clamav_milter_service_ensure,
  Boolean $clamav_milter_service_enable = $clamav::params::clamav_milter_service_enable,

  # Options
  Optional[Hash] $clamd_options         = $clamav::params::clamd_options,
  Optional[Hash] $freshclam_options     = $clamav::params::freshclam_options,
  Optional[Hash] $clamav_milter_options = $clamav::params::clamav_milter_options,
  Optional[Hash] $clamd_default_options      = undef,
  Optional[Hash] $freshclam_default_options  = undef,
  Optional[Hash] $milter_default_options     = undef,
) inherits clamav::params {

  # Determine real values using pick() to avoid undef
  $clamav_package_real        = pick($clamav_package, $clamav::params::clamav_package)
  $clamd_package_real          = pick($clamd_package, $clamav::params::clamd_package)
  $freshclam_package_real      = pick($freshclam_package, $clamav::params::freshclam_package)
  $clamav_milter_package_real  = pick($clamav_milter_package, $clamav::params::clamav_milter_package)

  $uid_real   = pick($uid, $clamav::params::uid)
  $gid_real   = pick($gid, $clamav::params::gid)
  $home_real  = pick($home, $clamav::params::home)
  $shell_real = pick($shell, $clamav::params::shell)

  # Merge clamd/freshclam/milter options with defaults
  $_clamd_defaults = pick($clamd_default_options, $clamav::params::clamd_default_options)
  $_freshclam_defaults = pick($freshclam_default_options, $clamav::params::freshclam_default_options)
  $_milter_defaults = pick($milter_default_options, $clamav::params::clamav_milter_default_options)

  $_clamd_options      = merge($_clamd_defaults, $clamd_options)
  $_freshclam_options  = merge($_freshclam_defaults, $freshclam_options)
  $_clamav_milter_options = merge($_milter_defaults, $clamav_milter_options)

  # Manage repo if requested
  if $manage_repo {
    require 'epel'
  }

  # Manage user
  if $manage_user {
    anchor { 'clamav::begin': }
    -> class { 'clamav::user': }
    -> Class['clamav::install']
  }

  # Manage clamd
  if $manage_clamd {
    Class['clamav::install']
    -> class { 'clamav::clamd': }
    -> anchor { 'clamav::end': }
  }

  # Manage freshclam
  if $manage_freshclam {
    Class['clamav::install']
    -> class { 'clamav::freshclam': }
    -> anchor { 'clamav::end': }
  }

  # Manage clamav-milter
  if $manage_clamav_milter {
    Class['clamav::install']
    -> class { 'clamav::clamav_milter': }
    -> anchor { 'clamav::end': }
  }

  # Anchors for ordering
  anchor { 'clamav::begin': }
  -> class { 'clamav::install': }
  -> anchor { 'clamav::end': }
}

