# Install PEAR package manager
#
# === Parameters
#
# [*ensure*]
#   The package ensure of PHP pear to install and run pear auto_discover
#
# [*package*]
#   The package name for PHP pear
#
class php::pear (
  String $ensure            = $::php::pear_ensure,
  Optional[String] $package = undef,
) inherits ::php::params {

  if $caller_module_name != $module_name {
    warning('php::pear is private')
  }

  # Defaults for the pear package name
  if $package {
    $package_name = $package
  } else {
    if $facts['os']['name'] == 'Amazon' {
      # On Amazon Linux the package name is also just 'php-pear'.
      # This would normally not be problematic but if you specify a
      # package_prefix other than 'php' then it will fail.
      $package_name = "php-${::php::params::pear_package_suffix}"
    }
    else {
      case $facts['os']['family'] {
        'Debian': {
          # Debian is a litte stupid: The pear package is called 'php-pear'
          # even though others are called 'php5-fpm' or 'php5-dev'
          $package_name = "php-${::php::params::pear_package_suffix}"
        }
        'FreeBSD': {
          # On FreeBSD the package name is just 'pear'.
          $package_name = $::php::params::pear_package_suffix
        }
        default: {
          # This is the default for all other architectures
          $package_name = "${::php::package_prefix}${::php::params::pear_package_suffix}"
        }
      }
    }
  }

  # Default PHP come with xml module and no seperate package for it
  if $facts['os']['name'] == 'Ubuntu' and versioncmp($facts['os']['release']['full'], '16.04') >= 0 {
    ensure_packages(["${php::package_prefix}xml"], {
      ensure  => present,
      require => Class['::apt::update'],
    })

    package { $package_name:
      ensure  => $ensure,
      require => [Class['::apt::update'],Class['::php::cli'],Package["${php::package_prefix}xml"]],
    }
  } else {
    package { $package_name:
      ensure  => $ensure,
      require => Class['::php::cli'],
    }
  }
}
