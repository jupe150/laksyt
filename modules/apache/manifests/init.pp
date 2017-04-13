class apache {
	package {'apache2':
	ensure => installed ,
	allowcdrom => true ,
	}
	
	file { '/var/www/testi.com':
	ensure => 'directory' ,
	require => Package['apache2'] ,
        group => 'www-data',
        owner => 'root',
        mode => 0755,
	}

        file { '/var/www/testi.com/logs':
        ensure => 'directory' ,
        require => Package['apache2'] ,
        group => 'www-data',
        owner => 'root',
        mode => 0775,
        }

        file { '/var/www/testi.com/index.html':
        ensure => 'file' ,
        require => Package['apache2'] ,
	content => 'trolololo' ,
        group => 'www-data',
        owner => 'root',
	mode => 0755,
        }
	
	file { '/etc/apache2/sites-available/testi.com.conf':
    	ensure  => 'file' ,
    	content  => template("apache/testi.com.erb"),
        group => 'www-data',
        owner => 'root',
        mode => 0755,
	require => Package['apache2'] ,
	}
	
        file { '/etc/apache2/sites-enabled/testi.com.conf':
        ensure  => 'link' ,
	target => '/etc/apache2/sites-available/testi.com.conf' ,
	notify => Service['apache2'] ,
	require => Package['apache2'] ,
        }

        file { '/etc/apache2/sites-enabled/000-default.conf':
        ensure  => 'absent' ,
	require => Package['apache2'] ,
        }

	service { 'apache2':
  	ensure => running ,
  	enable => true ,
	require => Package['apache2'],
	}

   
}
