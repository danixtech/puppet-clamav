# @summary Manage clam user/group.
class clamav::user {
  if $clamav::group {
    group { 'clamav':
      ensure => present,
      name   => $clamav::group_real,
      gid    => $clamav::gid_real,
      system => true,
    }
  }

  if $clamav::user {
    user { 'clamav':
      ensure  => present,
      name    => $clamav::user_real,
      comment => $clamav::comment_real,
      uid     => $clamav::uid_real,
      gid     => $clamav::gid_real,
      groups  => $clamav::groups_real,
      home    => $clamav::home_real,
      shell   => $clamav::shell_real,
      system  => true,
    }
  }
}
