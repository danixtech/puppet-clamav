type Clamav::Package_ensure = Variant[
  Enum['present', 'installed', 'absent', 'purged', 'held', 'latest'],
  Pattern[/\A[0-9][A-Za-z0-9.+:~_-]*\z/],
]
