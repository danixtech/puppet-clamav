# @summary Manage one opt-in systemd scheduled scan.
define clamav::scheduled_scan (
  String[1] $calendar,
  Array[Clamav::Scan_path, 1] $paths,
  Enum['clamscan', 'clamdscan'] $scanner = 'clamscan',
  String[1] $user = 'root',
  Optional[Array[Clamav::Scan_path]] $excludes = undef,
  Optional[Clamav::Scan_path] $log = undef,
  Optional[Clamav::Scan_path] $quarantine_path = undef,
) {
  $unit = "clamav-scan-${name}"
  $exclude_args = $excludes ? {
    undef   => '',
    default => $excludes.map |Clamav::Scan_path $path| { " --exclude=${path}" }.join,
  }
  $log_arg = $log ? {
    undef   => '',
    default => " --log=${log}",
  }
  $quarantine_arg = $quarantine_path ? {
    undef   => '',
    default => " --move=${quarantine_path}",
  }
  $command = "/usr/bin/${scanner} --recursive${exclude_args}${log_arg}${quarantine_arg} ${paths.join(' ')}"

  file { "${unit}.service":
    ensure  => file,
    path    => "/etc/systemd/system/${unit}.service",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "[Unit]\nDescription=ClamAV scheduled scan ${name}\nAfter=clamav-daemon.service\n\n[Service]\nType=oneshot\nUser=${user}\nExecStart=${command}\n",
    notify  => Exec['clamav-systemd-daemon-reload'],
  }

  file { "${unit}.timer":
    ensure  => file,
    path    => "/etc/systemd/system/${unit}.timer",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "[Unit]\nDescription=Timer for ClamAV scheduled scan ${name}\n\n[Timer]\nOnCalendar=${calendar}\nPersistent=true\nUnit=${unit}.service\n\n[Install]\nWantedBy=timers.target\n",
    notify  => Exec['clamav-systemd-daemon-reload'],
  }

  service { $unit:
    ensure    => running,
    enable    => true,
    name      => "${unit}.timer",
    subscribe => [File["${unit}.timer"], Exec['clamav-systemd-daemon-reload']],
  }
}
