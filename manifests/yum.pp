# == Class: duo_unix::yum
#
# Provides duo_unix for a yum-based environment (e.g. RHEL/CentOS)
#
# === Authors
#
# Mark Stanislav <mstanislav@duosecurity.com>
#
class duo_unix::yum {
  $repo_uri = 'http://pkg.duosecurity.com'
  $package_state = $::duo_unix::package_version

  # Map Amazon Linux to RedHat equivalent releases
  # Map RedHat 5 to CentOS 5 equivalent releases
  if $::operatingsystem == 'Amazon' {
    $releasever = $::operatingsystemmajrelease ? {
      '2014'  => '6Server',
      default => undef,
    }
    $os = $::operatingsystem
  } elsif ( $::operatingsystem == 'RedHat' and
            $::operatingsystemmajrelease == 5 ) {
    $os = 'CentOS'
    $releasever = '$releasever'
  } elsif ( $::operatingsystem == 'OracleLinux' ) {
    $os = 'CentOS'
    $releasever = '$releasever'
  } else {
    $os = $::operatingsystem
    $releasever = '$releasever'
  }

  if $::osfamily == 'RedHat' and $duo_unix::manage_repo {
    exec { 'Duo Security GPG Import':
      command => "/bin/rpm --import ${duo_unix::gpg_file}",
      unless  => '/bin/rpm -qi gpg-pubkey | grep Duo > /dev/null 2>&1',
      before   => Yumrepo['duosecurity'],
      require  => File[$duo_unix::gpg_file];
    }

    yumrepo { 'duosecurity':
      descr    => 'Duo Security Repository',
      baseurl  => "${repo_uri}/${os}/${releasever}/\$basearch",
      gpgcheck => '1',
      enabled  => '1',
      before   => Package[$duo_unix::duo_package],
      require  => File[$duo_unix::gpg_file];
    }
  }

  if $duo_unix::manage_ssh {
    package { 'openssh-server':
      ensure => installed;
    }
  }

  package {  $duo_unix::duo_package:
    ensure  => $package_state,
  }

}

