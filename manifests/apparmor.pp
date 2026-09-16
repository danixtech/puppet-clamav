# @summary Optional local AppArmor policy and native config validation support.
# @param profiles Caller-supplied local policy files.
# @param validation_configs Internal mapping of confined validators to config paths.
# @param freshclam_config Compatibility alias for the original internal parameter.
class clamav::apparmor (
  Array[Clamav::Apparmor_profile] $profiles = [],
  Hash[Enum['freshclam', 'clamd'], Stdlib::Absolutepath] $validation_configs = {},
  Optional[Stdlib::Absolutepath] $freshclam_config = undef,
) {
  if $freshclam_config != undef and 'freshclam' in $validation_configs {
    fail('Specify either freshclam_config or validation_configs[freshclam], not both')
  }
  $configs = $freshclam_config ? {
    undef   => $validation_configs,
    default => $validation_configs + { 'freshclam' => $freshclam_config },
  }
  # Only these two binaries have profiles in the inspected Ubuntu packages.
  $profile_names = {
    'freshclam' => 'usr.bin.freshclam',
    'clamd'     => 'usr.sbin.clamd',
  }
  $generated_profiles = $configs.map |$validator, $config| {
    if $config !~ Pattern[/\A\/[a-zA-Z0-9_. \/-]+[a-zA-Z0-9_.-]\z/] or $config =~ /\/\.{1,2}(\/|\z)/ {
      fail("AppArmor ${validator}_config must be a normalized absolute filename containing only letters, digits, spaces, /, _, ., and -")
    }
    $local_profile = "/etc/apparmor.d/local/${profile_names[$validator]}"
    $caller_profiles = $profiles.filter |$profile| { $profile['path'] == $local_profile }
    if $caller_profiles.length > 1 {
      fail("Only one apparmor_profiles entry may manage ${local_profile}")
    }
    if $caller_profiles != [] and $caller_profiles[0]['ensure'] == 'absent' {
      fail("The ${validator} local AppArmor profile cannot be absent while managed validation is enabled")
    }
    $caller_content = $caller_profiles ? {
      []      => '',
      default => $caller_profiles[0]['content'],
    }
    $generated_profile = {
      'path'    => $local_profile,
      'ensure'  => 'present',
      'content' => "${caller_content}\n# Permit Puppet temporary ${validator} validation candidates.\n\"${config}*\" r,\n",
    }
    $generated_profile
  }
  $generated_paths = $generated_profiles.map |$profile| { $profile['path'] }
  $effective_profiles = $profiles.filter |$profile| { !($profile['path'] in $generated_paths) } + $generated_profiles

  $effective_profiles.each |Clamav::Apparmor_profile $profile| {
    file { "clamav apparmor ${profile['path']}":
      ensure  => $profile['ensure'],
      path    => $profile['path'],
      content => $profile['content'],
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }

  if $configs != {} {
    $helper = '/usr/local/sbin/clamav-apparmor'
    file { $helper:
      ensure => file,
      source => 'puppet:///modules/clamav/apparmor',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    # Upgrade the old module-owned helper; its Freshclam retry flag is reused.
    file { '/usr/local/sbin/clamav-freshclam-apparmor':
      ensure => absent,
      before => File[$helper],
    }

    $configs.each |$validator, $config| {
      $local_profile = "/etc/apparmor.d/local/${profile_names[$validator]}"
      $quoted_config = shellquote($config)
      $reload = "clamav-${validator}-apparmor-reload"
      $ready = "clamav-${validator}-apparmor-ready"
      exec { $reload:
        command     => "${helper} reload ${validator} ${quoted_config}",
        refreshonly => true,
        logoutput   => on_failure,
        subscribe   => [File[$helper], File["clamav apparmor ${local_profile}"]],
        before      => Exec[$ready],
      }
      # Detect failed refreshes, unloaded profiles and stale candidate policy
      # even when managed files already match and produce no refresh event.
      exec { $ready:
        command   => "${helper} reload ${validator} ${quoted_config}",
        unless    => "${helper} check ${validator} ${quoted_config}",
        logoutput => on_failure,
        require   => File[$helper],
        before    => File["${validator}.conf"],
      }
      $config_parent = dirname($config)
      File <| path == $config_parent |> -> File["clamav apparmor ${local_profile}"]
      Class['clamav::install'] -> File["clamav apparmor ${local_profile}"]
      if $validator == 'clamd' or $clamav::freshclam_package {
        Package[$validator] -> File["clamav apparmor ${local_profile}"]
        Package[$validator] ~> Exec[$reload]
      }
    }
  }
}
