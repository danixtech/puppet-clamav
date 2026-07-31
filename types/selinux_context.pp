type Clamav::Selinux_context = Struct[
  {
    'path'   => Stdlib::Absolutepath,
    'type'   => String[1],
    'ensure' => Enum['present', 'absent'],
  },
]
