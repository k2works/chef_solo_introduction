#
# Cookbook Name:: hello
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
log "Hello, Chef!"

%w{zsh gcc make libreadline-dev}.each do |pkg|
  package pkg do
    action :install
  end
end
