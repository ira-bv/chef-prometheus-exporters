#
# Cookbook Name:: prometheus_exporters
# Recipe:: filestat
#
# Copyright 2020, bluevine's devops monkies
#
# All rights reserved - Do Not Redistribute
#

unless node['prometheus_exporters']['disable']
  node_port = node['prometheus_exporters']['filestat']['port']
  interface_name = node['prometheus_exporters']['listen_interface']
  interface = node['network']['interfaces'][interface_name]
  listen_ip = interface['addresses'].find do |_address, data|
    data['family'] == 'inet'
  end.first

  filestat_exporter 'main' do
    web_listen_address "#{listen_ip}:#{node_port}"
    collector_working_directory node['prometheus_exporters']['filestat']['working_directory']
    user node['prometheus_exporters']['filestat']['user']
    action %i[install enable start]
  end
end
