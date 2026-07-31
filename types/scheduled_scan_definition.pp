type Clamav::Scheduled_scan_definition = Struct[
  {
    'name'             => Pattern[/\A[a-zA-Z0-9@._-]+\z/],
    'schedule'         => Pattern[/\A[^;\n]+\z/],
    'paths'            => Array[Clamav::Scan_path, 1],
    'excludes'         => Optional[Array[Clamav::Scan_path]],
    'scanner'          => Enum['clamscan', 'clamdscan'],
    'user'             => String[1],
    'log'              => Optional[Clamav::Scan_path],
    'quarantine_path'  => Optional[Clamav::Scan_path],
  },
]
