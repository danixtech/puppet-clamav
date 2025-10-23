# @summary Set up ClamAV parameters defaults etc.
class clamav::params {

  # Generic defaults for all OSes
  $manage_user                  = false
  $manage_clamd                 = false
  $manage_freshclam             = false
  $manage_clamav_milter         = false
  $clamd_service_ensure         = 'running'
  $clamd_service_enable         = true
  $freshclam_service_ensure     = 'running'
  $freshclam_service_enable     = true
  $clamav_milter_service_ensure = 'running'
  $clamav_milter_service_enable = true

  # Generic version defaults
  $clamav_version        = 'latest'
  $clamd_version         = 'latest'
  $freshclam_version     = 'latest'
  $clamav_milter_version = undef

  # Generic config paths
  $clamd_config      = '/etc/clamav/clamd.conf'
  $freshclam_config  = '/etc/clamav/freshclam.conf'
  $clamav_milter_config = '/etc/clamav/clamav-milter.conf'

  # Generic ClamAV options
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

  # Define OS facts
  $os_family = $facts['os']['family']
  $os_name   = $facts['os']['name']
  $os_major  = $facts['os']['release']['major']

  # Determine Version specific vars for  RHEL
  if $os_family == 'RedHat' {
    if Integer($os_major) < 8 {
      $freshclam_package_rhel = 'clamav-update'
      $freshclam_service_rhel = undef
    } else {
      $freshclam_package_rhel = 'clamav-freshclam'
      $freshclam_service_rhel = 'clamav-freshclam'
    }
  }

  # OS-specific overrides for packages
  $os_package_defaults = $os_family ? {
    'Debian' => {
      'clamav_package'        => 'clamav',
      'clamd_package'         => 'clamav-daemon',
      'freshclam_package'     => 'clamav-freshclam',
      'clamav_milter_package' => 'clamav-milter',
    },
    'RedHat' => {
      'clamav_package'        => 'clamav',
      'clamd_package'         => 'clamd',
      'freshclam_package'     => $freshclam_package_rhel,
      'clamav_milter_package' => 'clamav-milter',
    },
    default => fail("Unsupported OS family ${os_family}"),
  }

  # OS-specific overrides for services
  $os_service_defaults = $os_family ? {
    'Debian' => {
      'clamd_service'         => 'clamav-daemon',
      'freshclam_service'     => 'clamav-freshclam',
      'clamav_milter_service' => undef,
    },
    'RedHat' => {
      'clamd_service'         => 'clamd',
      'freshclam_service'     => $freshclam_service_rhel,
      'clamav_milter_service' => 'clamav-milter',
    },
  }

  # OS-specific overrides for users
  $os_user_defaults = $os_family ? {
    'Debian' => {
    },
    'RedHat' => {
      'user'    => 'clamscan',
      'comment' => 'Clamav scanner user',
      'home'    => '/',
      'shell'   => '/sbin/nologin',
      'group'   => 'clamscan',
    },
  }

  # Merge packages and services into final config
  $final_packages = merge({
    'clamav_package'        => 'clamav',
    'clamd_package'         => 'clamd',
    'freshclam_package'     => 'clamav-freshclam',
    'clamav_milter_package' => 'clamav-milter',
  }, $os_package_defaults)

  $final_services = merge({
    'clamd_service'         => 'clamd',
    'freshclam_service'     => 'clamav-freshclam',
    'clamav_milter_service' => 'clamav-milter',
  }, $os_service_defaults)

  $final_users = merge({
    'user'    => 'clamav',
    'comment' => undef,
    'uid'     => 496,
    'gid'     => 496,
    'home'    => '/var/lib/clamav',
    'shell'   => '/sbin/false',
    'group'   => 'clamav',
    'groups'  => undef,
  }, $os_user_defaults)

  # Single assignment variables
  $clamav_package        = $final_packages['clamav_package']
  $clamd_package         = $final_packages['clamd_package']
  $freshclam_package     = $final_packages['freshclam_package']
  $clamav_milter_package = $final_packages['clamav_milter_package']

  $clamd_service         = $final_services['clamd_service']
  $freshclam_service     = $final_services['freshclam_service']
  $clamav_milter_service = $final_services['clamav_milter_service']

  $user    = $final_users['user']
  $comment = $final_users['comment']
  $uid     = $final_users['uid']
  $gid     = $final_users['gid']
  $home    = $final_users['home']
  $shell   = $final_users['shell']
  $group   = $final_users['group']
  $groups  = $final_users['groups']

  # Final merged options
  $clamd_default_options = merge($default_clamd_options, {
    'LocalSocket' => '/var/run/clamav/clamd.sock',
    'LogFile'     => '/var/log/clamav/clamd.log',
    'PidFile'     => '/var/run/clamav/clamd.pid',
    'User'        => 'clamav',
  })

  $freshclam_default_options = merge($default_freshclam_options, {
    'DatabaseOwner' => 'clamav',
    'PidFile'       => '/var/run/clamav/freshclam.pid',
    'UpdateLogFile' => '/var/log/clamav/freshclam.log',
  })

  $user_clamav_milter_options = {}
  $clamav_milter_options = merge($default_clamav_milter_options, $user_clamav_milter_options)

}
