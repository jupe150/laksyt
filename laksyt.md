h3. a) SSHD. Konfiguroi SSH uuteen porttiin Puppetilla. 
b) Modulit Gittiin. Laita modulisi versionhallintaan niin, että saat ne helposti ajettua uudella Live-USB työpöydällä. 
c) Etusivu uusiksi. Vaihda Apachen oletusweppisivu (default website) Puppetilla. 
d) Vapaaehtoinen vaikea. Tee uusi määritelty tyyppi (defined type), joka tekee Apachen nimipohjaisia virtuaalipalvelimia (name based virtualhost). Voit simuloida nimipalvelun toimintaa käsin hosts-tiedostolla.

## Apachen konffaus ensiksi:
Luodaan init.pp -tiedosto apachea varten:

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
        before => Service['apache2'],
        }

        file { '/var/www/testi.com/logs':
        ensure => 'directory' ,
        require => Package['apache2'] ,
        group => 'www-data',
        owner => 'root',
        mode => 0775,
        before => Service['apache2'],
        }

        file { '/var/www/testi.com/index.html':
        ensure => 'file' ,
        require => Package['apache2'] ,
        content => 'trolololo' ,
        group => 'www-data',
        owner => 'root',
        mode => 0755,
        before => Service['apache2'],
        }

        file { '/etc/apache2/sites-available/testi.com.conf':
        ensure  => 'file' ,
        content  => template("apache/testi.com.erb"),
        group => 'www-data',
        owner => 'root',
        mode => 0755,
        before => Service['apache2'],
        }

        file { '/etc/apache2/sites-enabled/testi.com.conf':
        ensure  => 'link' ,
        target => '/etc/apache2/sites-available/testi.com.conf' ,
        before => Service['apache2'] ,
        notify => Service['apache2'] ,
        }

        file { '/etc/apache2/sites-enabled/000-default.conf':
        ensure  => 'absent' ,
        before => Service['apache2'] ,
        }

        service { 'apache2':
        ensure => running ,
        enable => true ,
        require => Package['apache2'],
        }

    }

Ajetaan tiedosto:

sudo puppet apply -e 'class {'apache':}'

Virheilmoitushan sieltä tuli:

Error: Could not set 'file' on ensure: No such file or directory @ dir_s_rmdir - /etc/apache2/sites-available/testi.com.conf20170413-1787-mc34x4.lock at 42:/etc/puppet/modules/apache/manifests/init.pp
Error: Could not set 'file' on ensure: No such file or directory @ dir_s_rmdir - /etc/apache2/sites-available/testi.com.conf20170413-1787-mc34x4.lock at 42:/etc/puppet/modules/apache/manifests/init.pp
Wrapped exception:
No such file or directory @ dir_s_rmdir - /etc/apache2/sites-available/testi.com.conf20170413-1787-mc34x4.lock
Error: /Stage[main]/Apache/File[/etc/apache2/sites-available/testi.com.conf]/ensure: change from absent to file failed: Could not set 'file' on ensure: No such file or directory @ dir_s_rmdir - /etc/apache2/sites-available/testi.com.conf20170413-1787-mc34x4.lock at 42:/etc/puppet/modules/apache/manifests/init.pp
Notice: /Stage[main]/Apache/File[/etc/apache2/sites-enabled/testi.com.conf]: Dependency File[/etc/apache2/sites-available/testi.com.conf] has failures: true
Warning: /Stage[main]/Apache/File[/etc/apache2/sites-enabled/testi.com.conf]: Skipping because of failed dependencies

Ongelmat johtuivat liian innokkaasta ”before” -lauseen käytöstä. Virheet merkattu ****virhe**** ja ellei perään ole esitetty muutettavaa kenttää, ne on poistettu eikä tilalle ole tullut mitään (tässä siis vanha init.pp):

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
        ****before => Service['apache2'],****
        }

        file { '/var/www/testi.com/logs':
        ensure => 'directory' ,
        require => Package['apache2'] ,
        group => 'www-data',
        owner => 'root',
        mode => 0775,
        ****before => Service['apache2'],****
        }

        file { '/var/www/testi.com/index.html':
        ensure => 'file' ,
        require => Package['apache2'] ,
        content => 'trolololo' ,
        group => 'www-data',
        owner => 'root',
        mode => 0755,
        ****before => Service['apache2'],****
        }

        file { '/etc/apache2/sites-available/testi.com.conf':
        ensure  => 'file' ,
        content  => template("apache/testi.com.erb"),
        group => 'www-data',
        owner => 'root',
        mode => 0755,
        ****before => Service['apache2'],****  --> require => Package['apache2']
        }

        file { '/etc/apache2/sites-enabled/testi.com.conf':
        ensure  => 'link' ,
        target => '/etc/apache2/sites-available/testi.com.conf' ,
        ****before => Service['apache2'] ,**** --> require => Package['apache2'] ,
        notify => Service['apache2'] ,
        }

        file { '/etc/apache2/sites-enabled/000-default.conf':
        ensure  => 'absent' ,
        ****before => Service['apache2'] ,**** --> require => Package['apache2'] ,
        }

        service { 'apache2':
        ensure => running ,
        enable => true ,
        require => Package['apache2'],
        }
    }

Template -tiedosto:

    Listen 8880 
    <VirtualHost *:8880>
        ServerAdmin admin@testi.com
        ServerName testi.com
        ServerAlias www.testi.com
        DocumentRoot /var/www/testi.com/
        ErrorLog /var/www/testi.com/logs/error.log
        CustomLog /var/www/testi.com/logs/access.log combined
    </VirtualHost>


## SSH:n konffaus

Sitten luodaan moduli SSH:lle:

aloitushakemisto /etc/puppet/modules/

    sudo mkdir ssh
    cd mkdir
    sudo mkdir manifests
    sudo mkdir templates
    cd manifests
    nano init.pp

muokataan init.pp:stä tällainen:

        class ssh {
        package {'ssh':
        ensure => installed ,
        allowcdrom => true ,
        }

        file { '/etc/ssh/sshd_config':
        ensure  => 'file' ,
        content  => template("ssh/sshd_config"),
        require => Package['ssh'] ,
        }

        service { 'ssh':
        ensure => running ,
        enable => true ,
        ****require => Package['apache2'], ****  --> require => Package['ssh'],
        }


    }

Tämän ajettuani sain virheilmoituksen:

Error: Could not find dependency Package[apache2] for Service[ssh] at /etc/puppet/modules/ssh/manifests/init.pp:17

Eli muutin tuon apache2:n vielä ssh:ksi, niin läpi meni ilman virheilmoituksia.

Templateen -tiedostoksi kopsasin tuon ssh:n alkuperäisen conffin ja muutin sinne kohdan:

Port 22 --> Port 22221

Sitten importataan vielä modulit Gittiin:

hakemistona: /home/jupe/.git/laksyt

    sudo cp -r /etc/puppet/modules/ .
    git add .
    git commit
    git pull
    git push

