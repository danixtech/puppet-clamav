# Freshclam mirror configuration

The optional typed `freshclam_mirror_policy` parameter exposes native
freshclam client settings without managing a mirror server:

```puppet
class { 'clamav':
  freshclam_mirror_policy => {
    'private_mirrors'   => ['https://mirror.example.test/clamav'],
    'database_mirrors'  => ['db.example.test'],
    'http_proxy_server' => 'proxy.example.test',
    'http_proxy_port'   => 8080,
    'tls_verify'        => true,
  },
}
```

The typed policy is translated to `PrivateMirror`, `DatabaseMirror`, proxy,
and `TLSVerify` directives. Existing `freshclam_options` remains supported and
wins when the same directive is supplied, preserving the raw option escape
hatch and existing replacement semantics.

This module is a client only. It does not publish signatures, synchronize a
server, clone source, or implement SIMP-specific rsync orchestration. Freshclam
continues to verify and install signed databases using its native update
mechanism. Proxy credentials should be supplied through protected Hiera data.
