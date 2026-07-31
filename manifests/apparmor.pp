# @summary Optional AppArmor local profile/fragments for custom ClamAV paths.
class clamav::apparmor (
  Array[Clamav::Apparmor_profile] $profiles = [],
) {
  $profiles.each |Clamav::Apparmor_profile $profile| {
    file { "clamav apparmor ${profile['path']}":
      ensure  => $profile['ensure'],
      path    => $profile['path'],
      content => $profile['content'],
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }
}
