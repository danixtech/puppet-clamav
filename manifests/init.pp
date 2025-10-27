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
  Optional[String] $user  = undef,
  Optional[String] $group = undef,
  Optional[Integer] $uid  = undef,
  Optional[Integer] $gid  = undef,
  Optional[Stdlib::Absolutepath] $home  = undef,
  Optional[Stdlib::Absolutepath] $shell = undef,
  Optional[String] $comment = undef,
  Optional[Array[String]] $groups = undef,

  # Configs
  Optional[Stdlib::Absolutepath] $clamd_config       = undef,
  Optional[Stdlib::Absolutepath] $freshclam_config   = undef,
  Optional[Stdlib::Absolutepath] $clamav_milter_config = undef,
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig   = undef,
  Optional[String] $freshclam_delay                  = undef,

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
  $clamav_package_real        = pick($clamav_package, $clamav::params::clamav_package, 'clamav')
  $clamd_package_real         = pick($clamd_package,  $clamav::params::clamd_package, 'clamd')
  $freshclam_package_real     = pick($freshclam_package, $clamav::params::freshclam_package, 'clamav-freshclam')
  $clamav_milter_package_real = pick($clamav_milter_package, $clamav::params::clamav_milter_package, 'clamav-milter')

  # Services
  $clamd_service_real             = pick($clamd_service, $clamav::params::clamd_service, 'clamd')
  $clamd_service_ensure_real      = pick($clamd_service_ensure, $clamav::params::clamd_service_ensure, 'running')
  $clamd_service_enable_real      = pick($clamd_service_enable, $clamav::params::clamd_service_enable, true)

  $freshclam_service_real         = pick($freshclam_service, $clamav::params::freshclam_service, 'freshclam')
  $freshclam_service_ensure_real  = pick($freshclam_service_ensure, $clamav::params::freshclam_service_ensure, 'running')
  $freshclam_service_enable_real  = pick($freshclam_service_enable, $clamav::params::freshclam_service_enable, true)

  $clamav_milter_service_ensure_real = pick($clamav_milter_service_ensure, $clamav::params::clamav_milter_service_ensure, 'running')
  $clamav_milter_service_enable_real = pick($clamav_milter_service_enable, $clamav::params::clamav_milter_service_enable, true)
  $clamav_milter_service_real        = pick($clamav_milter_service, $clamav::params::clamav_milter_service, 'clamav-milter')

  # User account
  $user_real  = pick($user,  $clamav::params::user, 'clamav')
  $group_real = pick($group, $clamav::params::group, 'clamav')
  $uid_real   = pick($uid,   $clamav::params::uid, 496)
  $gid_real   = pick($gid,   $clamav::params::gid, 496)
  $home_real  = pick($home,  $clamav::params::home, '/var/lib/clamav')
  $shell_real = pick($shell, $clamav::params::shell, '/sbin/false')
  $comment_real = pick($comment, $clamav::params::comment, 'ClamAV user')
  $groups_real  = pick($groups, $clamav::params::groups, [])

  # Config paths
  $clamd_config_real        = pick($clamd_config, $clamav::params::clamd_config, '/etc/clamav/clamd.conf')
  $freshclam_config_real    = pick($freshclam_config, $clamav::params::freshclam_config, '/etc/clamav/freshclam.conf')
  $clamav_milter_config_real = pick($clamav_milter_config, $clamav::params::clamav_milter_config, '/etc/clamav/clamav-milter.conf')
  $freshclam_sysconfig_real  = pick($freshclam_sysconfig, $clamav::params::freshclam_sysconfig, '/etc/default/freshclam')
  $freshclam_delay_real      = pick($freshclam_delay, $clamav::params::freshclam_delay, '0')

  ############################
  # Merge options with defaults
  ############################

  # clamd options
  $_clamd_options = merge(
    pick($clamd_default_options, $clamav::params::clamd_default_options, {}),
    $clamd_options
  )

  # freshclam options
  $_freshclam_options = merge(
    pick($freshclam_default_options, $clamav::params::freshclam_default_options, {}),
    $freshclam_options
  )

  # clamav_milter options
  $_clamav_milter_options = merge(
    pick($milter_default_options, $clamav::params::clamav_milter_default_options, {}),
    $clamav_milter_options
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
      -> class { 'clamav::clamd': }
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

  # Ensure anchors exist if user management is skipped
  anchor { 'clamav::begin': }
    -> class { 'clamav::install': }
    -> anchor { 'clamav::end': }
}
