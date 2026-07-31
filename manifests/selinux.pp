# @summary Optional SELinux integration for caller-managed ClamAV paths.
class clamav::selinux (
  Array[Clamav::Selinux_context] $file_contexts = [],
  Array[String[1]] $booleans = [],
) {
  # The puppet-selinux module is an explicit integration dependency only when
  # this class is enabled. It is intentionally not loaded for default catalogs.
  $file_contexts.each |Clamav::Selinux_context $context| {
    selinux::fcontext { "clamav ${context['path']}":
      path    => $context['path'],
      seltype => $context['type'],
      ensure  => $context['ensure'],
    }
  }

  $booleans.each |String[1] $boolean| {
    selinux::boolean { "clamav ${boolean}":
      name  => $boolean,
      value => true,
    }
  }
}
