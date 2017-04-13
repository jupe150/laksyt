	class ssh {
        package {'ssh':
        ensure => installed ,
        allowcdrom => true ,
        }

        file { '/etc/ssh/sshd_config':
        ensure  => 'file' ,
        content  => template("ssh/sshd_config"),
        require => Package['ssh'] ,
	notify => Service['ssh'],
        }
															 
        service { 'ssh':
        ensure => running ,
        enable => true ,
        require => Package['ssh'],
        }


}

