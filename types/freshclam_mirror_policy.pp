type Clamav::Freshclam_mirror_policy = Struct[
  {
    'private_mirrors'       => Optional[Array[String[1]]],
    'database_mirrors'      => Optional[Array[String[1]]],
    'http_proxy_server'     => Optional[String[1]],
    'http_proxy_port'       => Optional[Integer[1, 65535]],
    'http_proxy_username'   => Optional[String[1]],
    'http_proxy_password'   => Optional[String[1]],
    'tls_verify'            => Optional[Boolean],
  },
]
