入門CHEF SOLO
======================
# 目的
# 前提
| ソフトウェア   | バージョン   | 備考        |
|:---------------|:-------------|:------------|
| OS X           |10.9.2        |             |
| vagrant        |1.6.0        |             |
| chef           |10.14.2        |             |
| ruby           |2.1.1        |             |
| rvm            |1.24.0        |             |

# 構成
+ [セットアップ](#1)
+ [Hello Chef](#2)
+ [nginxをChef Soloで立ち上げる](#3)
+ [リモートからchef-soloを実行する](#4)
+ [レシピを使って実行する流れをおさらい](#5)
+ [td-agentのレシピを読む](#6)

# 詳細
## <a name="1">セットアップ</a>
### Vagrant環境構築
```bash
$ vagrant init hashicorp/precise32
$ vagrant up
```
_Vagrantfile_を編集してスタティックIPの設定をする
```ruby
config.vm.network "private_network", ip: "192.168.50.12"
```
```bash
$ vagrant reload
```
sshアクセスできるようにする
```bash
$ vagrant ssh-config --host melody >> ~/.ssh/config
$ ssh melody
```
_Vagrantfile_を編集してプロビジョニングの設定をする
```ruby
config.vm.provision :shell, :path => "bootstrap.sh"
```
_bootstrap.sh_を用意する
```bash
#!/usr/bin/env bash
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
apt-get update
apt-get install -y curl
\curl -sSL https://get.rvm.io | bash -s stable
apt-get install -y git
```
プロビジョニング実行
```bash
$ vagrant provision
```
## <a name="2">Hello Chef!</a>
### レポジトリ（キッチン）、クックブック、レシピ
```bash
$ ssh melody
$ cd /vagrant
$ git clone http://github.com/opscode/chef-repo.git
$ knife configure
WARNING: No knife configuration file found
Where should I put the config file? [/home/vagrant/.chef/knife.rb]
Please enter the chef server URL: [http://precise32:4000]
Please enter an existing username or clientname for the API: [vagrant]
Please enter the validation clientname: [chef-validator]
Please enter the location of the validation key: [/etc/chef/validation.pem]
Please enter the path to a chef repository (or leave blank):
*****

You must place your client key in:
  /home/vagrant/.chef/vagrant.pem
Before running commands with Knife!

*****

You must place your validation key in:
  /etc/chef/validation.pem
Before generating instance data with Knife!

*****
Configuration file written to /home/vagrant/.chef/knife.rb
$ cd chef-repo
$ knife cookbook create hello -o cookbooks
** Creating cookbook hello
** Creating README for cookbook: hello
** Creating CHANGELOG for cookbook: hello
** Creating metadata for cookbook: hello
```

### レシピの編集
_chef-repo/hello/recipes/default.rb_
```ruby
#
# Cookbook Name:: hello
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
log "Hello, Chef!"
```
### Chef Soloの実行
_chef-repo/localhost.json
```javascript
// localhost.json
{
  "run_list" : [
    "recipe[hello]"
  ]
}
```
_chef-repo/solo.rb_
```ruby
file_cache_path "/tmp/chef-solo"
cookbook_path ["/vagrant/chef-repo/cookbooks"]
```

```bash
$ sudo chef-solo -c solo.rb -j ./localhost.json
[2014-05-07T09:41:27+00:00] INFO: *** Chef 10.14.2 ***
[2014-05-07T09:41:27+00:00] INFO: Setting the run_list to ["recipe[hello]"] from JSON
[2014-05-07T09:41:27+00:00] INFO: Run List is [recipe[hello]]
[2014-05-07T09:41:27+00:00] INFO: Run List expands to [hello]
[2014-05-07T09:41:27+00:00] INFO: Starting Chef Run for precise32
[2014-05-07T09:41:27+00:00] INFO: Running start handlers
[2014-05-07T09:41:27+00:00] INFO: Start handlers complete.
[2014-05-07T09:41:27+00:00] INFO: Processing log[Hello, Chef!] action write (hello::default line 9)
[2014-05-07T09:41:27+00:00] INFO: Hello, Chef!
[2014-05-07T09:41:27+00:00] INFO: Chef Run complete in 0.049349 seconds
[2014-05-07T09:41:27+00:00] INFO: Running report handlers
[2014-05-07T09:41:27+00:00] INFO: Report handlers complete
```

### パッケージをインストールする
_chef-repo/cookbooks/recipes/default.rb_
```ruby
package "zsh" do
  action :install
end
```

```bash
$ sudo chef-solo -c solo.rb -j ./localhost.json
[2014-05-07T09:45:31+00:00] INFO: *** Chef 10.14.2 ***
[2014-05-07T09:45:31+00:00] INFO: Setting the run_list to ["recipe[hello]"] from JSON
[2014-05-07T09:45:31+00:00] INFO: Run List is [recipe[hello]]
[2014-05-07T09:45:31+00:00] INFO: Run List expands to [hello]
[2014-05-07T09:45:31+00:00] INFO: Starting Chef Run for precise32
[2014-05-07T09:45:31+00:00] INFO: Running start handlers
[2014-05-07T09:45:31+00:00] INFO: Start handlers complete.
[2014-05-07T09:45:31+00:00] INFO: Processing log[Hello, Chef!] action write (hello::default line 9)
[2014-05-07T09:45:31+00:00] INFO: Hello, Chef!
[2014-05-07T09:45:31+00:00] INFO: Processing package[zsh] action install (hello::default line 11)
[2014-05-07T09:45:41+00:00] INFO: Chef Run complete in 10.064104 seconds
[2014-05-07T09:45:41+00:00] INFO: Running report handlers
[2014-05-07T09:45:41+00:00] INFO: Report handlers complete
```
_chef-repo/cookbooks/recipes/default.rb_を書き換える
```ruby
%w{zsh gcc make libreadline-dev}.each do |pkg|
  package pkg do
    action :install
  end
end
```

```bash
$ sudo chef-solo -c solo.rb -j ./localhost.json
[2014-05-07T09:56:55+00:00] INFO: *** Chef 10.14.2 ***
[2014-05-07T09:56:56+00:00] INFO: Setting the run_list to ["recipe[hello]"] from JSON
[2014-05-07T09:56:56+00:00] INFO: Run List is [recipe[hello]]
[2014-05-07T09:56:56+00:00] INFO: Run List expands to [hello]
[2014-05-07T09:56:56+00:00] INFO: Starting Chef Run for precise32
[2014-05-07T09:56:56+00:00] INFO: Running start handlers
[2014-05-07T09:56:56+00:00] INFO: Start handlers complete.
[2014-05-07T09:56:56+00:00] INFO: Processing log[Hello, Chef!] action write (hello::default line 9)
[2014-05-07T09:56:56+00:00] INFO: Hello, Chef!
[2014-05-07T09:56:56+00:00] INFO: Processing package[zsh] action install (hello::default line 12)
[2014-05-07T09:56:56+00:00] INFO: Processing package[gcc] action install (hello::default line 12)
[2014-05-07T09:56:56+00:00] INFO: Processing package[make] action install (hello::default line 12)
[2014-05-07T09:56:56+00:00] INFO: Processing package[libreadline-dev] action install (hello::default line 12)
[2014-05-07T09:56:56+00:00] INFO: Chef Run complete in 0.144641 seconds
[2014-05-07T09:56:56+00:00] INFO: Running report handlers
[2014-05-07T09:56:56+00:00] INFO: Report handlers complete
```

## <a name="3">nginxをChef Soloで立ち上げる</a>
### レシピ
```bash
$ vagrant up
$ ssh melody
$ cd /vagrant/chef-repo/
$ knife cookbook create nginx -o cookbooks
WARNING: No knife configuration file found
** Creating cookbook nginx
** Creating README for cookbook: nginx
** Creating CHANGELOG for cookbook: nginx
** Creating metadata for cookbook: nginx
```
_cookbooks/nginx/recipes/default.rb_にレシピを書く
```ruby
package "nginx" do
  action :install
end

service "nginx" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

template "nginx.conf" do
  path "/etc/nginx/nginx.conf"
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :reload, 'service[nginx]'
end
```
_cookbooks/nginx/templates/default/nginx.conf.erb_にテンプレートを配置する。
```
user www-data;
worker_processes 1;
error_log /var/log/nginx/error.log;
pid /var/run/nginx.pid;

events {
  worker_connections 1024;
}

http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  server {
    listen <%= node['nginx']['port'] %>;
    server_name localhost;
    location / {
      root /usr/share/nginx/html;
      index index.html index.htm;
    }
  }
}
```
_localhost.json_を編集
```javascript
{
  "nginx": {
    "port" : 80
  },
  "run_list" : [
    "nginx"
  ]
}
```

### chef-solo実行
実行後に_http://192.168.50.12_にアクセスしてnginxが起動していることを確認する。

```bash
$ sudo chef-solo -c solo.rb -j ./localhost.json
[2014-05-09T02:25:26+00:00] INFO: *** Chef 10.14.2 ***
[2014-05-09T02:25:27+00:00] INFO: Setting the run_list to ["nginx"] from JSON
[2014-05-09T02:25:27+00:00] INFO: Run List is [recipe[nginx]]
[2014-05-09T02:25:27+00:00] INFO: Run List expands to [nginx]
[2014-05-09T02:25:27+00:00] INFO: Starting Chef Run for precise32
[2014-05-09T02:25:27+00:00] INFO: Running start handlers
[2014-05-09T02:25:27+00:00] INFO: Start handlers complete.
[2014-05-09T02:25:27+00:00] INFO: Processing package[nginx] action install (nginx::default line 9)
[2014-05-09T02:25:27+00:00] INFO: Processing service[nginx] action enable (nginx::default line 13)
[2014-05-09T02:25:27+00:00] INFO: Processing service[nginx] action start (nginx::default line 13)
[2014-05-09T02:25:27+00:00] INFO: Processing template[nginx.conf] action create (nginx::default line 18)
[2014-05-09T02:25:27+00:00] INFO: Chef Run complete in 0.5936 seconds
[2014-05-09T02:25:27+00:00] INFO: Running report handlers
[2014-05-09T02:25:27+00:00] INFO: Report handlers complete
```

## <a name="4">リモートからchef-soloを実行する</a>

### knife-soloの導入
```bash
$ gem install knife-solo
```
Vagrantで最新のChefを使えるようにする。  
プラグインを追加  
```bash
$ vagrant plugin install vagrant-omnibus
```
_Vagrantfile_に以下を追加
```
config.omnibus.chef_version = :latest
```
再セットアップ
```bash
$ vagrant destroy
$ vagrant up
```

#### knife-soloの基本操作

```bash
# <host>にchef-soloをインストールする
$ knife solo prepare <host>
$ knife solo prepare <user>@<host>

# レシピ転送&リモート操作
$ knife solo cook <host>

# run_listを個別に指定
$ knife solo cook <host> -o hello::default,nginx::default

# <host>に転送したレシピ郡を削除して掃除する
$ knife solo clean <host>

# 新規Chefレポジトリを作る
$ knife solo init chef-repo
```

#### 複数ホストへのknife soloの実行
```bash
$ echo user@node1 user@node2 user@node3 | xargs -n knife solo cook
```

## <a name="5">レシピを使って実行する流れをおさらい</a>
### vagrant up
```bash
$ vagrant up
```
### Chefレポジトリを作成
```bash
$ knife solo init chef-repo2
$ cd chef-repo2
$ git init
$ git add .
$ git commit -m 'first commit'
```
### knife solo prepare

```bash
$ knife solo prepare melody
$ git add nodes/melody.json
$ git commit -m 'add node json file'
```
上記の操作は[うまくいかない](https://github.com/k2works/chef_solo_introduction/issues/1) 。  
しかし、最新のChefを適用する設定をVagrantにしているので以下の作業は実行できる。

### クックブック作成&レシピ編集
```bash
$ knife cookbook create nginx -o site-cookbooks
** Creating cookbook nginx
** Creating README for cookbook: nginx
** Creating CHANGELOG for cookbook: nginx
** Creating metadata for cookbook: nginx
```
あとはレシピやJSONファイルを編集する。  
_site-cookbooks/nginx/recipes/default.rb_
```ruby
package "nginx" do
  action :install
end

service "nginx" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

template "nginx.conf" do
  path "/etc/nginx/nginx.conf"
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :reload, 'service[nginx]'
end
```
_nodes/melody.json_
```javascript
{
  "nginx": {
    "port" : 80
  },
  "run_list" : [
    "nginx"
  ]
}
```
_site-cookbooks/nginx/templates/default/nginx.conf.erb_
```ruby
user www-data;
worker_processes 1;
error_log /var/log/nginx/error.log;
pid /var/run/nginx.pid;

events {
  worker_connections 1024;
}

http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  server {
    listen <%= node['nginx']['port'] %>;
    server_name localhost;
    location / {
      root /usr/share/nginx/html;
      index index.html index.htm;
    }
  }
}
```
### Chef Solo実行
```bash
$ knife solo cook melody
Running Chef on melody...
Checking Chef version...
Uploading the kitchen...
Generating solo config...
Running Chef...
[2014-05-09T07:09:45+00:00] WARN:
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
SSL validation of HTTPS requests is disabled. HTTPS connections are still
encrypted, but chef is not able to detect forged replies or man in the middle
attacks.

To fix this issue add an entry like this to your configuration file:


  # Verify all HTTPS connections (recommended)
  ssl_verify_mode :verify_peer

  # OR, Verify only connections to chef-server
  verify_api_cert true


To check your SSL configuration, or troubleshoot errors, you can use the
`knife ssl check` command like so:


  knife ssl check -c /home/vagrant/chef-solo/solo.rb


* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Starting Chef Client, version 11.12.4
Compiling Cookbooks...
Converging 3 resources
Recipe: nginx::default
  * package[nginx] action install
    - install version 1.1.19-1ubuntu0.6 of package nginx

  * service[nginx] action enable (up to date)
  * service[nginx] action start
    - start service service[nginx]

  * template[nginx.conf] action create
    - update content in file /etc/nginx/nginx.conf from 38154b to 034db2
        --- /etc/nginx/nginx.conf       2012-03-29 02:50:24.000000000 +0000
        +++ /tmp/chef-rendered-template20140509-5228-1cjnwyt    2014-05-09 07:09:52.363757261 +0000
        @@ -1,96 +1,23 @@
         user www-data;
        -worker_processes 4;
        +worker_processes 1;
        +error_log /var/log/nginx/error.log;
         pid /var/run/nginx.pid;

         events {
        -       worker_connections 768;
        -       # multi_accept on;
        +  worker_connections 1024;
         }

         http {
        +  include /etc/nginx/mime.types;
        +  default_type application/octet-stream;

        -       ##
        -       # Basic Settings
        -       ##
        -
        -       sendfile on;
        -       tcp_nopush on;
        -       tcp_nodelay on;
        -       keepalive_timeout 65;
        -       types_hash_max_size 2048;
        -       # server_tokens off;
        -
        -       # server_names_hash_bucket_size 64;
        -       # server_name_in_redirect off;
        -
        -       include /etc/nginx/mime.types;
        -       default_type application/octet-stream;
        -
        -       ##
        -       # Logging Settings
        -       ##
        -
        -       access_log /var/log/nginx/access.log;
        -       error_log /var/log/nginx/error.log;
        -
        -       ##
        -       # Gzip Settings
        -       ##
        -
        -       gzip on;
        -       gzip_disable "msie6";
        -
        -       # gzip_vary on;
        -       # gzip_proxied any;
        -       # gzip_comp_level 6;
        -       # gzip_buffers 16 8k;
        -       # gzip_http_version 1.1;
        -       # gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
        -
        -       ##
        -       # nginx-naxsi config
        -       ##
        -       # Uncomment it if you installed nginx-naxsi
        -       ##
        -
        -       #include /etc/nginx/naxsi_core.rules;
        -
        -       ##
        -       # nginx-passenger config
        -       ##
        -       # Uncomment it if you installed nginx-passenger
        -       ##
        -
        -       #passenger_root /usr;
        -       #passenger_ruby /usr/bin/ruby;
        -
        -       ##
        -       # Virtual Host Configs
        -       ##
        -
        -       include /etc/nginx/conf.d/*.conf;
        -       include /etc/nginx/sites-enabled/*;
        +  server {
        +    listen 80;
        +    server_name localhost;
        +    location / {
        +      root /usr/share/nginx/html;
        +      index index.html index.htm;
        +    }
        +  }
         }
        -
        -
        -#mail {
        -#      # See sample authentication script at:
        -#      # http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
        -#
        -#      # auth_http localhost/auth.php;
        -#      # pop3_capabilities "TOP" "USER";
        -#      # imap_capabilities "IMAP4rev1" "UIDPLUS";
        -#
        -#      server {
        -#              listen     localhost:110;
        -#              protocol   pop3;
        -#              proxy      on;
        -#      }
        -#
        -#      server {
        -#              listen     localhost:143;
        -#              protocol   imap;
        -#              proxy      on;
        -#      }
        -#}

  * service[nginx] action reload
    - reload service service[nginx]


Running handlers:
Running handlers complete

Chef Client finished, 4/5 resources updated in 7.225893057 seconds
```
実行の確認ができたら。
```bash
$ git add site-cookbooks/nginx
$ git commit -m 'Add nginx recipe'
```

## <a name="6">td-agentのレシピを読む</a>
### インストール
```bash
$ gem install knife-github-cookbooks
$ knife solo init chef-repo3
$ cd chef-ropo3
$ knife cookbook github install treasure-data/chef-td-agent
$ knife cookbook github install opscode-cookbooks/apt
$ knife cookbook github install opscode-cookbooks/yum
```
定義ファイル作成
```bash
$ knife solo prepare melody
```
_nodes/melody.json_
```javascript
{"run_list":["td-agent","apt","yum"]}
```
レシピ適用
```bash
$ knife solo cook melody
Running Chef on melody...
Checking Chef version...
Uploading the kitchen...
Generating solo config...
Running Chef...
[2014-05-09T06:10:44+00:00] WARN:
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
SSL validation of HTTPS requests is disabled. HTTPS connections are still
encrypted, but chef is not able to detect forged replies or man in the middle
attacks.

To fix this issue add an entry like this to your configuration file:


  # Verify all HTTPS connections (recommended)
  ssl_verify_mode :verify_peer

  # OR, Verify only connections to chef-server
  verify_api_cert true


To check your SSL configuration, or troubleshoot errors, you can use the
`knife ssl check` command like so:


  knife ssl check -c /home/vagrant/chef-solo/solo.rb


* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Starting Chef Client, version 11.12.4
Compiling Cookbooks...
Converging 16 resources
Recipe: td-agent::default
  * group[td-agent] action create
    - create group[td-agent]

  * user[td-agent] action create
    - create user user[td-agent]

  * user[td-agent] action manage (up to date)
  * directory[/etc/td-agent/] action create
    - create new directory /etc/td-agent/
    - change mode from '' to '0755'
    - change owner from '' to 'td-agent'
    - change group from '' to 'td-agent'

  * apt_repository[treasure-data] action addRecipe: <Dynamically Defined Resource>
  * file[/var/lib/apt/periodic/update-success-stamp] action nothing (skipped due to action :nothing)
  * execute[apt-cache gencaches] action nothing (skipped due to action :nothing)
  * execute[apt-get update] action nothing (skipped due to action :nothing)
  * file[/etc/apt/sources.list.d/treasure-data.list] action create
    - create new file /etc/apt/sources.list.d/treasure-data.list
    - update content in file /etc/apt/sources.list.d/treasure-data.list from none to 481855
        --- /etc/apt/sources.list.d/treasure-data.list  2014-05-09 06:10:47.402088403 +0000
        +++ /tmp/.treasure-data.list20140509-12317-1jdnyl       2014-05-09 06:10:47.406088402 +0000
        @@ -1 +1,2 @@
        +deb     http://packages.treasure-data.com/precise/ precise contrib
    - change mode from '' to '0644'
    - change owner from '' to 'root'
    - change group from '' to 'root'

  * file[/var/lib/apt/periodic/update-success-stamp] action delete (up to date)
  * execute[apt-get update] action run
    - execute apt-get update -o Dir::Etc::sourcelist='sources.list.d/treasure-data.list' -o Dir::Etc::sourceparts='-' -o APT::Get::List-Cleanup='0'

  * execute[apt-cache gencaches] action run
    - execute apt-cache gencaches



Recipe: td-agent::default
  * template[/etc/td-agent/td-agent.conf] action create
    - create new file /etc/td-agent/td-agent.conf
    - update content in file /etc/td-agent/td-agent.conf from none to 9e0e68
        --- /etc/td-agent/td-agent.conf 2014-05-09 06:10:52.326088249 +0000
        +++ /tmp/chef-rendered-template20140509-12317-114rr9    2014-05-09 06:10:52.326088249 +0000
        @@ -1 +1,56 @@
        +####
        +## Output descriptions:
        +##
        +
        +# Treasure Data (http://www.treasure-data.com/) provides cloud based data
        +# analytics platform, which easily stores and processes data from td-agent.
        +# FREE plan is also provided.
        +# @see http://docs.fluentd.org/articles/http-to-td
        +#
        +# This section matches events whose tag is td.DATABASE.TABLE
        +<match td.*.*>
        +  type tdlog
        +  apikey
        +
        +  auto_create_table
        +  buffer_type file
        +  buffer_path /var/log/td-agent/buffer/td
        +</match>
        +
        +## match tag=debug.** and dump to console
        +<match debug.**>
        +  type stdout
        +</match>
        +
        +####
        +## Source descriptions:
        +##
        +
        +## built-in TCP input
        +## @see http://docs.fluentd.org/articles/in_forward
        +<source>
        +  type forward
        +  port 24224
        +</source>
        +
        +## built-in UNIX socket input
        +#<source>
        +#  type unix
        +#</source>
        +
        +# HTTP input
        +# POST http://localhost:8888/<tag>?json=<json>
        +# POST http://localhost:8888/td.myapp.login?json={"user"%3A"me"}
        +# @see http://docs.fluentd.org/articles/in_http
        +<source>
        +  type http
        +  port 8888
        +</source>
        +
        +## live debugging agent
        +<source>
        +  type debug_agent
        +  bind 127.0.0.1
        +  port 24230
        +</source>
    - change mode from '' to '0644'

  * package[td-agent] action upgrade
    - upgrade package td-agent from uninstalled to 1.1.19-1

  * service[td-agent] action enable (up to date)
  * service[td-agent] action start (up to date)
Recipe: apt::default
  * execute[apt-get-update] action run
    - execute apt-get update

  * execute[apt-get update] action nothing (skipped due to action :nothing)
  * execute[apt-get autoremove] action nothing (skipped due to action :nothing)
  * execute[apt-get autoclean] action nothing (skipped due to action :nothing)
  * package[update-notifier-common] action install
    - install version 0.119ubuntu8.6 of package update-notifier-common

  * execute[apt-get-update] action run
    - execute apt-get update

  * execute[apt-get-update-periodic] action run (skipped due to only_if)
  * directory[/var/cache/local] action create
    - create new directory /var/cache/local
    - change mode from '' to '0755'
    - change owner from '' to 'root'
    - change group from '' to 'root'

  * directory[/var/cache/local/preseeding] action create
    - create new directory /var/cache/local/preseeding
    - change mode from '' to '0755'
    - change owner from '' to 'root'
    - change group from '' to 'root'

Recipe: yum::default
  * yum_globalconfig[/etc/yum.conf] action createRecipe: <Dynamically Defined Resource>
  * template[/etc/yum.conf] action create
    - create new file /etc/yum.conf
    - update content in file /etc/yum.conf from none to 185984
        --- /etc/yum.conf       2014-05-09 06:12:01.243452995 +0000
        +++ /tmp/chef-rendered-template20140509-12317-17u9hsw   2014-05-09 06:12:01.251456156 +0000
        @@ -1 +1,15 @@
        +# This file was generated by Chef
        +# Do NOT modify this file by hand.
        +
        +[main]
        +cachedir=/var/cache/yum/$basearch/$releasever
        +debuglevel=2
        +distroverpkg=ubuntu-release
        +exactarch=1
        +gpgcheck=1
        +installonly_limit=3
        +keepcache=0
        +logfile=/var/log/yum.log
        +obsoletes=1
        +plugins=1
    - change mode from '' to '0644'



Recipe: td-agent::default
  * service[td-agent] action restart
    - restart service service[td-agent]


Running handlers:
Running handlers complete

Chef Client finished, 17/21 resources updated in 78.627232079 seconds
```
# 参照
+ [CHEF](http://www.getchef.com/)
+ [About Resources and Providers](http://docs.opscode.com/resource.html)
+ [Chef Community Cookbooks](https://github.com/opscode-cookbooks)
