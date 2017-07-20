curl-pkg:
  pkg:
    - name: curl
    - installed

lua-cjson-pkg:
  pkg:
    - name: lua-cjson
    - installed

lua-filesystem-pkg:
  pkg:
    - name: lua-filesystem
    - installed

nginx-pkg:
  pkg:
    - name: nginx-extras
    - installed

nginx_configtest:
  cmd.wait:
    - name: /usr/sbin/nginx -t
    - watch:
      - file: /etc/nginx/sites-available/*
      - file: /etc/nginx/sites-enabled/*
    - require:
      - pkg: nginx-pkg

nginx:
  service:
    - running
    - enable: True
    - reload: True
    - watch:
      - cmd: nginx_configtest

/srv/www:
  file.directory:
    - makedirs: True
    - user: www-data
    - group: www-data

/srv/www/www.freeradius.org:
  file.symlink:
    - target: /vagrant/_site

# Remove default site
/etc/nginx/sites-enabled/default:
  file.absent

/etc/nginx/sites-available/default:
  file.absent

/etc/nginx/sites-available:
  file.recurse:
    - source: salt://nginx/sites-available
    - file_mode: 640

/etc/nginx/conf.d:
  file.recurse:
    - source: salt://nginx/conf.d
    - file_mode: 640

{% for site in ['www.freeradius.org']
                %}
/etc/nginx/sites-enabled/{{ site }}:
  file.symlink:
    - target: /etc/nginx/sites-available/{{ site }}
{% endfor %}


