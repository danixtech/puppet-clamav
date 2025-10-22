# @summary Set up ClamAV parameters defaults etc.
class clamav::params {

  # Generic defaults for all OSes
  $manage_user                  = false
  $manage_clamd                 = false
  $manage_clamav_milter         = false
  $manage_freshclam             = false
  $clamd_service_ensure         = 'running'
  $clamd_service_enable         = true
  $freshclam_service_ensure     = 'running'
  $freshclam_service_enable     = true
  $clamav_milter_service_ensure = 'running'
  $clamav_milter_service_enable = true

  # Generic package defaults
  $clamav_package = 'clamav'
  $clamav_version = 'latest'

  $clamd_package  = 'clamd'
  $clamd_version  = 'latest'
  $freshclam_package = 'clamav-freshclam'
  $freshclam_version = 'latest'
  $clamav_milter_package = undef
  $clamav_milter_version = undef

  # Generic defaults for ClamAV options
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
    'LocalSocketMode'          => '666',
    'LogClean'                 => false,
    'LogFacility'              => 'LOG_LOCAL6',
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
  }

  $default_freshclam_options = {
    'Bytecode'                 => true,
    'Checks'                   => '24',
    'CompressLocalDatabase'    => 'no',
    'ConnectTimeout'           => '30',
    'DNSDatabaseInfo'          => 'current.cvd.clamav.net',
    'DatabaseDirectory'        => '/var/lib/clamav',
    'DatabaseMirror'           => ['db.local.clamav.net', 'database.clamav.net'],
    'DatabaseOwner'            => 'clamav',
    'Debug'                    => false,
    'Foreground'               => false,
    'LogFacility'              => 'LOG_LOCAL6',
    'LogFileMaxSize'           => '0',
    'LogRotate'                => true,
    'LogSyslog'                => false,
    'LogTime'                  => true,
    'LogVerbose'               => false,
    'MaxAttempts'              => '5',
    'PidFile'                  => '/var/run/clamav/freshclam.pid',
    'ReceiveTimeout'           => '30',
    'ScriptedUpdates'          => 'yes',
    'TestDatabases'            => 'yes',
    'UpdateLogFile'            => '/var/log/clamav/freshclam.log',
  }

  $default_clamav_milter_options = {
    'User'         => 'clamilt',
    'MilterSocket' => 'inet:8890@localhost',
    'ClamdSocket'  => 'tcp:127.0.0.1',
    'LogSyslog'    => 'yes',
  }

  # OS-specific overrides
  $os_overrides = {
    'RedHat' => {
      '6'  => {
        'user'                          => 'clam',
        'group'                         => 'clam',
        'home'                          => '/var/lib/clamav',
        'shell'                         => '/sbin/nologin',
        'clamd_package'                 => 'clamd',
        'freshclam_package'             => undef,
        'clamav_milter_package'         => undef,
        'clamd_service'                 => 'clamd',
        'freshclam_service'             => undef,
        'clamav_milter_service'         => undef,
        'clamd_localsocket'             => '/var/run/clamav/clamd.sock',
        'clamd_logfile'                 => '/var/log/clamav/clamd.log',
        'clamd_pidfile'                 => '/var/run/clamav/clamd.pid',
        'freshclam_databaseowner'       => 'clam',
        'freshclam_updatelogfile'       => '/var/log/clamav/freshclam.log',
        'freshclam_sysconfig'           => undef,
        'freshclam_delay'               => undef,
        'clamav_milter_default_options' => undef,
      },
      '7'  => {
        'user'                          => 'clamscan',
        'group'                         => 'clamscan',
        'home'                          => '/',
        'shell'                         => '/sbin/nologin',
        'clamd_package'                 => 'clamav-scanner-systemd',
        'freshclam_package'             => 'clamav-update',
        'clamav_milter_package'         => 'clamav-milter-systemd',
        'clamd_service'                 => 'clamd@scan',
        'freshclam_service'             => 'clamav-freshclam',
        'clamav_milter_service'         => 'clamav-milter',
        'clamd_localsocket'             => '/var/run/clamd.scan/clamd.sock',
        'clamd_pidfile'                 => '/var/run/clamd.scan/clamd.pid',
        'freshclam_databaseowner'       => 'clamupdate',
        'freshclam_updatelogfile'       => undef,
        'freshclam_sysconfig'           => '/etc/sysconfig/freshclam',
        'freshclam_delay'               => undef,
        'clamav_milter_default_options' => $default_clamav_milter_options,
      },
      '8'  => {
        'freshclam_service' => 'clamav-freshclam',
      },
      '9'  => {},
      '10' => {},
    },
    'Debian' => {
      'default' => {
        'user'                          => 'clamav',
        'group'                         => 'clamav',
        'home'                          => '/var/lib/clamav',
        'shell'                         => '/bin/false',
        'clamd_package'                 => 'clamav-daemon',
        'freshclam_package'             => 'clamav-freshclam',
        'clamd_service'                 => 'clamav-daemon',
        'freshclam_service'             => 'clamav-freshclam',
        'clamav_milter_package'         => undef,
        'clamav_milter_service'         => undef,
        'clamd_localsocket'             => '/var/run/clamav/clamd.ctl',
        'clamd_logfile'                 => '/var/log/clamav/clamav.log',
        'clamd_pidfile'                 => '/var/run/clamav/clamd.pid',
        'freshclam_databaseowner'       => 'clamav',
        'freshclam_updatelogfile'       => '/var/log/clamav/freshclam.log',
        'freshclam_sysconfig'           => undef,
        'freshclam_delay'               => undef,
        'clamav_milter_default_options' => undef,
      },
    },
    'Ubuntu' => {
      '12.04' => {}, '14.04' => {}, '16.04' => {},
      '18.04' => {}, '20.04' => {}, '22.04' => {}, '24.04' => {},
    }
  }

  # Determine OS override
  $os_family = $facts['os']['family']
  $os_name   = $facts['os']['name']
  $os_major  = $facts['os']['release']['major']
  $os_full   = $facts['os']['release']['full']

  if ! $os_overrides[$os_family] {
    fail("ClamAV module not supported on OS family ${os_family}")
  }

  if $os_overrides[$os_family][$os_major] {
    $os_config = merge($default_clamd_options, $os_overrides[$os_family][$os_major])
  } elsif $os_overrides[$os_family]['default'] {
    $os_config = merge($default_clamd_options, $os_overrides[$os_family]['default'])
  } else {
    $os_config = $default_clamd_options
  }

  # Assign variables
  $user                          = $os_config['user']
  $group                         = $os_config['group']
  $home                          = $os_config['home']
  $shell                         = $os_config['shell']
  $clamd_package                 = $os_config['clamd_package']
  $freshclam_package             = $os_config['freshclam_package']
  $clamav_milter_package         = $os_config['clamav_milter_package']
  $clamd_service                 = $os_config['clamd_service']
  $freshclam_service             = $os_config['freshclam_service']
  $clamav_milter_service         = $os_config['clamav_milter_service']
  $clamd_localsocket             = $os_config['clamd_localsocket']
  $clamd_logfile                 = $os_config['clamd_logfile']
  $clamd_pidfile                 = $os_config['clamd_pidfile']
  $freshclam_databaseowner       = $os_config['freshclam_databaseowner']
  $freshclam_updatelogfile       = $os_config['freshclam_updatelogfile']
  $freshclam_sysconfig           = $os_config['freshclam_sysconfig']
  $freshclam_delay               = $os_config['freshclam_delay']
  $clamav_milter_default_options = $os_config['clamav_milter_default_options']

  # Merge OS specific defaults into final options
  $clamd_default_options = merge($default_clamd_options, {
    'LocalSocket' => $clamd_localsocket,
    'LogFile'     => $clamd_logfile,
    'PidFile'     => $clamd_pidfile,
    'User'        => $user,
  })

  $freshclam_pidfile_final = $os_config['freshclam_pidfile'] ? {
    undef   => $default_freshclam_options['PidFile'],
    default => $os_config['freshclam_pidfile'],
  }

  $freshclam_default_options = merge($default_freshclam_options, {
    'DatabaseOwner' => $freshclam_databaseowner,
    'PidFile'       => $freshclam_pidfile_final,
    'UpdateLogFile' => $freshclam_updatelogfile,
  })

}
