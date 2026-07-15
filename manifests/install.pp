# @summary Installs clamav package
class clamav::install {
  package { 'clamav':
    ensure => $clamav::clamav_version_real,
    name   => $clamav::clamav_package_real,
  }
}
