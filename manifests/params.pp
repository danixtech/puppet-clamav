class clamav::params {

  # Generic management flags
  $manage_user          = false
  $manage_repo          = false
  $manage_clamd         = false
  $manage_freshclam     = false
  $manage_clamav_milter = false

  # ClamAV Daemon Package
  case $facts['os']['family'] {
    'Debian': {
      $clamd_package_default = 'clamav-daemon'
    }
    'RedHat': {
      $clamd_package_default = 'clamd'
    }
  }

  $clamav_package_default        = 'clamav'
  $freshclam_package_default     = 'clamav-freshclam'
  $clamav_milter_package_default = 'clamav-milter'

  $clamav_version_default        = 'latest'
  $clamd_version_default         = 'latest'
  $freshclam_version_default     = 'latest'
  $clamav_milter_version_default = undef

  # Services
  $clamd_service_default        = 'clamd'
  $clamd_service_ensure_default = 'running'
  $clamd_service_enable_default = true

  $freshclam_service_default        = 'freshclam'
  $freshclam_service_ensure_default = 'running'
  $freshclam_service_enable_default = true

  $clamav_milter_service_default        = 'clamav-milter'
  $clamav_milter_service_ensure_default = 'running'
  $clamav_milter_service_enable_default = true

  # User account
  $user_default    = 'clamav'
  $group_default   = 'clamav'
  $uid_default     = 496
  $gid_default     = 496
  $home_default    = '/var/lib/clamav'
  $shell_default   = '/sbin/false'
  $comment_default = 'ClamAV user'
  $groups_default  = []

  # Generic paths
  $clamd_config_default         = '/etc/clamav/clamd.conf'
  $freshclam_config_default     = '/etc/clamav/freshclam.conf'
  $clamav_milter_config_default = '/etc/clamav/clamav-milter.conf'
  $freshclam_sysconfig_default  = '/etc/default/freshclam'
  $freshclam_delay_default      = 0

  # Generic ClamAV defaults (baseline configuration)
  $default_clamd_options = {
    'AllowAllMatchScan'        => true,
    'Bytecode'                 => true,
    'BytecodeSecurity'         => 'TrustSigned',
    'BytecodeTimeout'          => '60000',
    'CommandReadTimeout'       => '5',
    'CrossFilesystems'         => true,
    'DatabaseDirectory'        => '/var/lib/clamav',
    'Debug'                    => false,
    'DetectPUA'                => false,
    'DisableCertCheck'         => false,
    'ExitOnOOM'                => false,
    'ExtendedDetectionInfo'    => true,
    'FixStaleSocket'           => true,
    'FollowDirectorySymlinks'  => false,
    'FollowFileSymlinks'       => false,
    'ForceToDisk'              => false,
    'Foreground'               => false,
    'HeuristicScanPrecedence'  => false,
    'IdleTimeout'              => '30',
    'LeaveTemporaryFiles'      => false,
    'LocalSocket'              => '/var/run/clamd.scan/clamd.sock',
    'LocalSocketGroup'         => 'clamav',
    'LocalSocketMode'          => '666',
    'LogClean'                 => false,
    'LogFacility'              => 'LOG_LOCAL6',
    'LogFile'                  => '/var/log/clamav/clamd.log',
    'LogFileMaxSize'           => '0',
    'LogFileUnlock'            => false,
    'LogRotate'                => true,
    'LogSyslog'                => false,
    'LogTime'                  => true,
    'LogVerbose'               => false,
    'MaxConnectionQueueLength' => '15',
    'MaxDirectoryRecursion'    => '15',
    'MaxEmbeddedPE'            => '10M',
    'MaxHTMLNoTags'            => '2M',
    'MaxHTMLNormalize'         => '10M',
    'MaxQueue'                 => '100',
    'MaxScriptNormalize'       => '5M',
    'MaxThreads'               => '12',
    'MaxZipTypeRcg'            => '1M',
    'OfficialDatabaseOnly'     => false,
    'PhishingScanURLs'         => true,
    'PhishingSignatures'       => true,
    'PidFile'                  => '/var/run/clamav/clamd.pid',
    'ReadTimeout'              => '180',
    'ScanArchive'              => true,
    'ScanELF'                  => true,
    'ScanHTML'                 => true,
    'ScanMail'                 => true,
    'ScanOLE2'                 => true,
    'ScanOnAccess'             => false,
    'ScanPE'                   => true,
    'ScanPartialMessages'      => false,
    'ScanSWF'                  => true,
    'SelfCheck'                => '3600',
    'SendBufTimeout'           => '200',
    'StreamMaxLength'          => '25M',
    'StructuredDataDetection'  => false,
    'TemporaryDirectory'       => '/tmp',
    'AlgorithmicDetection'     => true,
    'ArchiveBlockEncrypted'    => false,
    'OLE2BlockMacros'          => false,
    'PhishingAlwaysBlockCloak' => false,
    'PhishingAlwaysBlockSSLMismatch' => false,
  }

  $default_freshclam_options = {
    'Bytecode'              => true,
    'Checks'                => '24',
    'CompressLocalDatabase' => 'no',
    'ConnectTimeout'        => '30',
    'DNSDatabaseInfo'       => 'current.cvd.clamav.net',
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
    'DatabaseMirror'        => ['db.local.clamav.net','database.clamav.net'],
  }

  $default_clamav_milter_options = {
    'User'        => 'clamilt',
    'MilterSocket'=> 'inet:8890@localhost',
    'ClamdSocket' => 'tcp:127.0.0.1',
    'LogSyslog'   => 'yes',
  }

  # Looking up OS specific overrides from Hiera
  $os_clamd_defaults = lookup('clamav::clamd_default_options', Hash, 'deep', {})
  $os_freshclam_defaults = lookup('clamav::freshclam_default_options', Hash, 'deep', {})
  $os_milter_defaults = lookup('clamav::clamav_milter_default_options', Hash, 'deep', {})

  # Merge base defaults with OS-specific overrides from module Hiera
  $clamd_default_options    = merge($default_clamd_options, $os_clamd_defaults)
  $freshclam_default_options = merge($default_freshclam_options, $os_freshclam_defaults)
  $clamav_milter_default_options = merge($default_clamav_milter_options, $os_milter_defaults)
}
