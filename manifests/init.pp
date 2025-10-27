class clamav (
  Boolean $manage_user          = $clamav::params::manage_user,
  Boolean $manage_repo          = $clamav::params::manage_repo,
  Boolean $manage_clamd         = $clamav::params::manage_clamd,
  Boolean $manage_freshclam     = $clamav::params::manage_freshclam,
  Boolean $manage_clamav_milter = $clamav::params::manage_clamav_milter,

  String $clamav_package        = $clamav::params::clamav_package,
  String $clamav_version        = $clamav::params::clamav_version,

  String $user                  = $clamav::params::user,
  Optional[String] $comment     = $clamav::params::comment,
  Integer $uid                  = $clamav::params::uid,
  Integer $gid                  = $clamav::params::gid,
  Stdlib::Absolutepath $home    = $clamav::params::home,
  Stdlib::Absolutepath $shell   = $clamav::params::shell,
  String $group                 = $clamav::params::group,
  Optional[Array[String]] $groups = $clamav::params::groups,

  String $clamd_package         = $clamav::params::clamd_package,
  String $clamd_version         = $clamav::params::clamd_version,
  Stdlib::Absolutepath $clamd_config = $clamav::params::clamd_config,
  String $clamd_service         = $clamav::params::clamd_service,
  String $clamd_service_ensure  = $clamav::params::clamd_service_ensure,
  Boolean $clamd_service_enable = $clamav::params::clamd_service_enable,
  Hash $clamd_options           = $clamav::params::clamd_options,

  String $freshclam_package            = $clamav::params::freshclam_package,
  String $freshclam_version            = $clamav::params::freshclam_version,
  Stdlib::Absolutepath $freshclam_config = $clamav::params::freshclam_config,
  String $freshclam_service            = $clamav::params::freshclam_service,
  String $freshclam_service_ensure     = $clamav::params::freshclam_service_ensure,
  Boolean $freshclam_service_enable    = $clamav::params::freshclam_service_enable,
  Hash $freshclam_options              = $clamav::params::freshclam_options,
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig = $clamav::params::freshclam_sysconfig,
  Optional[String] $freshclam_delay   = $clamav::params::freshclam_delay,

  Optional[String] $clamav_milter_package        = $clamav::params::clamav_milter_package,
  Optional[String] $clamav_milter_version        = $clamav::params::clamav_milter_version,
  Optional[Stdlib::Absolutepath] $clamav_milter_config = $clamav::params::clamav_milter_config,
  Optional[String] $clamav_milter_service        = $clamav::params::clamav_milter_service,
  String $clamav_milter_service_ensure           = $clamav::params::clamav_milter_service_ensure,
  Boolean $clamav_milter_service_enable          = $clamav::params::clamav_milter_service_enable,
  Hash $clamav_milter_options                    = $clamav::params::clamav_milter_options,

  Optional[Hash] $clamd_default_options       = undef,
  Optional[Hash] $freshclam_default_options   = undef,
  Optional[Hash] $milter_default_options      = undef,
) inherits clamav::params {

  # Merge defaults with Hiera / class parameters
  $_clamd_options = merge(
    $clamd_default_options ? { undef => $clamav::params::clamd_default_options, default => $clamd_default_options },
    $clamd_options           ? { undef => {}, default => $clamd_options }
  )

  $_freshclam_options = merge(
    $freshclam_default_options ? { undef => $clamav::params::freshclam_default_options, default => $freshclam_default_options },
    $freshclam_options         ? { undef => {}, default => $freshclam_options }
  )

  $_clamav_milter_options = merge(
    $milter_default_options ? { undef => $clamav::params::clamav_milter_default_options, default => $milter_default_options },
    $clamav_milter_options  ? { undef => {}, default => $clamav_milter_options }
  )

  # Repo management
  if $manage_repo {
    require 'epel'
  }

  # User management
  if $manage_user {
    anchor { 'clamav::begin': } ->
    class { 'clamav::user': } ->
    class { 'clamav::install': }
  }

  # clamd service
  if $manage_clamd {
    class { 'clamav::install': } ->
    class { 'clamav::clamd':
      options => $_clamd_options,
    } ->
    anchor { 'clamav::end': }
  }

  # freshclam service
  if $manage_freshclam {
    class { 'clamav::install': } ->
    class { 'clamav::freshclam':
      options => $_freshclam_options,
    } ->
    anchor { 'clamav::end': }
  }

  # clamav-milter service
  if $manage_clamav_milter {
    class { 'clamav::install': } ->
    class { 'clamav::clamav_milter':
      options => $_clamav_milter_options,
    } ->
    anchor { 'clamav::end': }
  }

  # Ensure anchors exist if not already
  anchor { 'clamav::begin': }
  anchor { 'clamav::end': }
}

