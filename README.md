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
user nginx;
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
user nginx;
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
[2014-05-09T05:14:01+00:00] WARN:
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
  * package[nginx] action install (up to date)
  * service[nginx] action enable (up to date)
  * service[nginx] action start (up to date)
  * template[nginx.conf] action create (up to date)

Running handlers:
Running handlers complete

Chef Client finished, 0/4 resources updated in 2.616735291 seconds
```
初回実行はエラーが出るが２回めからは出なくなる。  
実行の確認ができたら。
```bash
$ git add site-cookbooks/nginx
$ git commit -m 'Add nginx recipe'
```


# 参照
