# @summary Set up ClamAV parameter defaults for supported OSes
class clamav::params {

  # Management flags
  $manage_user          = false
  $manage_clamd         = false
  $manage_freshclam     = false
  $manage_clamav_milter = false

  $clamd_service_ensure         = 'running'
  $clamd_service_enable         = true
  $freshclam_service_ensure     = 'running'
  $freshclam_service_enable     = true
  $clamav_milter_service_ensure = 'running'
  $clamav_milter_service_enable = true

  # Generic package defaults (always defined)
  $clamav_package        = 'clamav'
  $clamav_version        = 'latest'
  $clamd_package         = undef
  $clamd_version         = 'latest'
  $freshclam_package     = undef
  $freshclam_version     = 'latest'
  $clamav_milter_package = undef
  $clamav_milter_version = undef

  # Config paths
  $clamd_config      = '/etc/clamav/clamd.conf'
  $freshclam_config  = '/etc/clamav/freshclam.conf'
  $clamav_milter_config = '/etc/clamav/clamav-milter.conf'

  # Default clamd options
  $default_clamd_options = {
    'AllowAllMatchScan'       => true,
    'Bytecode'                => true,
    'BytecodeSecurity'        => 'TrustSigned',
    'BytecodeTimeout'         => '60000',
    'CommandReadTimeout'      => '5',
    'CrossFilesystems'        => true,
    'DatabaseDirectory'       => '/var/lib/clamav',
    'Debug'                   => false,
    'DetectPUA'               => false,
    'ExitOnOOM'               => false,
    'ExtendedDetectionInfo'   => true,
    'FixStaleSocket'          => true,
    'FollowDirectorySymlinks' => false,
    'FollowFileSymlinks'      => false,
    'ForceToDisk'             => false,
    'Foreground'              => false,
    'IdleTimeout'             => '30',
    'LeaveTemporaryFiles'     => false,
    'LocalSocketMode'         => '666',
    'LogClean'                => false,
    'LogFacility'             => 'LOG_LOCAL6',
    'LogFileMaxSize'          => '0',
    'LogRotate'               => true,
    'LogSyslog'               => false,
    'LogTime'                 => true,
    'LogVerbose'              => false,
  }

  # Default freshclam options
  $default_freshclam_options = {
    'Bytecode'              => true,
    'Checks'                => '24',
    'CompressLocalDatabase' => 'no',
    'ConnectTimeout'        => '30',
    'DatabaseDirectory'     => '/var/lib/clamav',
    'DatabaseOwner'         => 'clamav',
    'Debug'                 => false,
    'Foreground'            => false,
    'LogFacility'           => 'LOG_LOCAL6',
    'LogFileMaxSize'        => '0',
    'LogRotate'             => true,
    'LogSyslog'             => false,
    'LogTime'               => true,
    'LogVerbose'            => false,
    'MaxAttempts'           => '5',
    'PidFile'               => '/var/run/clamav/freshclam.pid',
    'ReceiveTimeout'        => '30',
    'ScriptedUpdates'       => 'yes',
    'TestDatabases'         => 'yes',
    'UpdateLogFile'         => '/var/log/clamav/freshclam.log',
  }

  # Default clamav-milter options
  $default_clamav_milter_options = {
    'User'         => 'clamilt',
    'MilterSocket' => 'inet:8890@localhost',
    'ClamdSocket'  => 'tcp:127.0.0.1',
    'LogSyslog'    => 'yes',
  }

  # OS-specific defaults
  case $facts['os']['family'] {
    'Debian': {
      $clamd_package         = 'clamav-daemon'
      $freshclam_package     = 'clamav-freshclam'
      $clamav_milter_package = 'clamav-milter'
      $user                  = 'clamav'
      $group                 = 'clamav'
      $home                  = '/var/lib/clamav'
      $shell                 = '/bin/false'
    }
    'RedHat': {
      $clamd_package         = 'clamd'
      $freshclam_package     = $facts['os']['release']['major'] >= '8' ? { true => 'clamav-freshclam', false => 'clamav-update' }
      $clamav_milter_package = 'clamav-milter'
      $user                  = 'clam'
      $group                 = 'clam'
      $home                  = '/var/lib/clamav'
      $shell                 = '/sbin/nologin'
    }
    default: {
      fail("ClamAV module not supported on OS family ${facts['os']['family']}")
    }
  }

}
