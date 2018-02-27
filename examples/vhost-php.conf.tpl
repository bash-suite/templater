{{EMAIL=$USER@$DOMAIN}}
{{FCGI_SERVER=127.0.0.1}}
{{FCGI_PORT=9000}}
{{FCGI=$FCGI_SERVER:$FCGI_PORT}}
{{DOC_ROOT=/home/$USER/sites/$DOMAIN/htdocs}}
{{LOG_DIR=/var/log/apache2}}
<VirtualHost *:80>
  ServerAdmin {{EMAIL}}
  ServerName {{DOMAIN}}
  ServerAlias www.{{DOMAIN }}

  <FilesMatch \.php$>
    SetHandler proxy:fcgi://{{ FCGI }}
  </FilesMatch>

  DocumentRoot {{  DOC_ROOT  }}

  <Directory {{  DOC_ROOT  }}>
    AllowOverride all
    Order allow,deny
    Allow From all
  </Directory>

  LogLevel warn
  ErrorLog {{LOG_DIR}}/{{DOMAIN}}.error.log
  CustomLog {{LOG_DIR}}/{{DOMAIN}}.access.log combined
</VirtualHost>
