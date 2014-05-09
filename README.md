入門CHEF SOLO
======================
# 目的
# 前提
| ソフトウェア   | バージョン   | 備考        |
|:---------------|:-------------|:------------|
| OS X           |10.8.5        |             |
| vagrant        |1.6.0        |             |
| chef           |10.14.2        |             |

# 構成
+ [セットアップ](#1)
+ [Hello Chef](#2)
+ [nginxをChef Soloで立ち上げる](#3)

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
# 参照
