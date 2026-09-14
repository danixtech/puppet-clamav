# @summary Optional AppArmor local profile/fragments for custom ClamAV paths.
# @param profiles Caller-supplied local policy files.
# @param freshclam_config Internal Ubuntu Freshclam validation path; undef disables automatic policy.
class clamav::apparmor (
  Array[Clamav::Apparmor_profile] $profiles = [],
  Optional[Stdlib::Absolutepath] $freshclam_config = undef,
) {
  $local_profile = '/etc/apparmor.d/local/usr.bin.freshclam'
  if $freshclam_config {
    # Quote spaces, but reject policy metacharacters rather than interpreting
    # a caller path as AppArmor syntax. The only glob is our suffix wildcard.
    if $freshclam_config !~ Pattern[/\A\/[a-zA-Z0-9_. \/-]+[a-zA-Z0-9_.-]\z/] {
      fail('AppArmor freshclam_config must contain only letters, digits, spaces, /, _, ., and - and end in a filename')
    }
    $caller_profiles = $profiles.filter |$profile| { $profile['path'] == $local_profile }
    if $caller_profiles.length > 1 {
      fail('Only one apparmor_profiles entry may manage the Freshclam local profile')
    }
    if $caller_profiles != [] and $caller_profiles[0]['ensure'] == 'absent' {
      fail('The Freshclam local AppArmor profile cannot be absent while managed validation is enabled')
    }
    $caller_content = $caller_profiles ? {
      []      => '',
      default => $caller_profiles[0]['content'],
    }
    $effective_profiles = $profiles.filter |$profile| { $profile['path'] != $local_profile } + [{
        'path'    => $local_profile,
        'ensure'  => 'present',
        'content' => "${caller_content}\n# Permit Puppet temporary Freshclam validation candidates.\n\"${freshclam_config}*\" r,\n",
    }]
  } else {
    $effective_profiles = $profiles
  }

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

  if $freshclam_config {
    $helper = '/usr/local/sbin/clamav-freshclam-apparmor'
    $quoted_config = shellquote($freshclam_config)
    file { $helper:
      ensure => file,
      source => 'puppet:///modules/clamav/freshclam-apparmor',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      notify => Exec['clamav-freshclam-apparmor-reload'],
    }

    exec { 'clamav-freshclam-apparmor-reload':
      command     => "${helper} reload ${quoted_config}",
      refreshonly => true,
      logoutput   => on_failure,
      require     => File[$helper],
      subscribe   => File["clamav apparmor ${local_profile}"],
      before      => Exec['clamav-freshclam-apparmor-ready'],
    }

    # Retry after a failed reload, or externally reverted loaded policy, even
    # when the managed fragment already matches and produces no refresh.
    exec { 'clamav-freshclam-apparmor-ready':
      command   => "${helper} reload ${quoted_config}",
      unless    => "${helper} check ${quoted_config}",
      logoutput => on_failure,
      require   => File[$helper],
      before    => File['freshclam.conf'],
    }

    $config_parent = dirname($freshclam_config)
    File <| path == $config_parent |> -> File["clamav apparmor ${local_profile}"]
    Class['clamav::install'] -> File["clamav apparmor ${local_profile}"]
    if $clamav::freshclam_package {
      Package['freshclam'] -> File["clamav apparmor ${local_profile}"]
      Package['freshclam'] ~> Exec['clamav-freshclam-apparmor-reload']
    }
  }
}
