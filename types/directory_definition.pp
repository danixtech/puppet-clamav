type Clamav::Directory_definition = Struct[
  {
    'path'  => Stdlib::Absolutepath,
    'owner' => Optional[String[1]],
    'group' => Optional[String[1]],
    'mode'  => Optional[Stdlib::Filemode],
  },
]
