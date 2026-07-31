type Clamav::Apparmor_profile = Struct[
  {
    'path'    => Stdlib::Absolutepath,
    'content' => String,
    'ensure'  => Enum['present', 'absent'],
  },
]
