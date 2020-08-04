#
# Cookbook Name:: prometheus_exporters
# Resource:: filestat
#
# Copyright 2020, bluevine's devops monkies
#
# All rights reserved - Do Not Redistribute
#

resource_name :filestat_exporter

property :globes_enabled, Array, callbacks: {
  'should be a globe' => lambda do |globes|
    globes.all? { |element| globe_LIST.include? element }
  end,
}, default: node['prometheus_exporters']['filestat']['globes_enabled'].dup
property :log_format, String, default: 'logger:stdout'
property :log_level, String, default: 'info'
property :user, String, default: 'root'
property :web_listen_address, String, default: ':9202'
property :web_telemetry_path, String, default: '/metrics'
property :collector_working_directory, String, default: '/var/lib/filestat_exporter/textfile_collector'

property :custom_options, String

action :install do
  # Set property that can be queried with Chef search
  node.default['prometheus_exporters']['filestat']['enabled'] = true

  service_name = "filestat_exporter_#{new_resource.name}"
  options = " -config.file /usr/local/etc/#{service_name}.yaml"

  # Create config file - template should be replaced with code in the future?
  template "/usr/local/etc/#{service_name}.yaml" do
    source 'filestat.yaml.erb'
    owner 'root'
    group 'root'
    mode '0444'
    variables (
      workdir:            new_resource[collector_working_directory],
      globes:             new_resource[globes_enabled],
      web_listen_address: new_resource[web_listen_address],
      web_telemetry_path: new_resource[web_telemetry_path],
    )
    action :create
  end

  # Download binary
  remote_file 'filestat_exporter' do
    path "#{Chef::Config[:file_cache_path]}/filestat_exporter.tar.gz"
    owner 'root'
    group 'root'
    mode '0644'
    source node['prometheus_exporters']['filestat']['url']
    checksum node['prometheus_exporters']['filestat']['checksum']
    notifies :restart, "service[#{service_name}]"
  end

  bash 'untar filestat_exporter' do
    code "tar -xzf #{Chef::Config[:file_cache_path]}/filestat_exporter.tar.gz -C /opt"
    action :nothing
    subscribes :run, 'remote_file[filestat_exporter]', :immediately
  end

  link '/usr/local/sbin/filestat_exporter' do
    to "/opt/filestat_exporter-#{node['prometheus_exporters']['filestat']['version']}.linux-amd64/filestat_exporter"
  end

  # Configure to run as a service
  service service_name do
    action :nothing
  end

  case node['init_package']
  when /init/
    %w[
      /var/run/prometheus
      /var/log/prometheus
    ].each do |dir|
      directory dir do
        owner 'root'
        group 'root'
        mode '0755'
        recursive true
        action :create
      end
    end

    directory "/var/log/prometheus/#{service_name}" do
      owner new_resource.user
      group 'root'
      mode '0755'
      action :create
    end

    template "/etc/init.d/#{service_name}" do
      cookbook 'prometheus_exporters'
      source 'initscript.erb'
      owner 'root'
      group 'root'
      mode '0755'
      variables(
        name: service_name,
        user: new_resource.user,
        cmd: "/usr/local/sbin/filestat_exporter #{options}",
        service_description: 'Prometheus filestat Exporter',
      )
      notifies :restart, "service[#{service_name}]"
    end

  when /systemd/
    systemd_unit "#{service_name}.service" do
      content(
        'Unit' => {
          'Description' => 'Systemd unit for Prometheus filestat Exporter',
          'After' => 'network.target remote-fs.target apiserver.service',
        },
        'Service' => {
          'Type' => 'simple',
          'User' => new_resource.user,
          'ExecStart' => "/usr/local/sbin/filestat_exporter #{options}",
          'WorkingDirectory' => '/',
          'Restart' => 'on-failure',
          'RestartSec' => '30s',
        },
        'Install' => {
          'WantedBy' => 'multi-user.target',
        },
      )
      notifies :restart, "service[#{service_name}]"
      action :create
    end

  when /upstart/
    template "/etc/init/#{service_name}.conf" do
      cookbook 'prometheus_exporters'
      source 'upstart.conf.erb'
      owner 'root'
      group 'root'
      mode '0644'
      variables(
        cmd: "/usr/local/sbin/filestat_exporter #{options}",
        user: new_resource.user,
        service_description: 'Prometheus filestat Exporter',
      )
      notifies :restart, "service[#{service_name}]"
    end

  else
    raise "Init system '#{node['init_package']}' is not supported by the 'prometheus_exporters' cookbook"
  end

  if new_resource.globe_textfile_directory and
     new_resource.globe_textfile_directory != ''
    directory 'globe_textfile_directory' do
      path new_resource.globe_textfile_directory
      owner 'root'
      group 'root'
      mode '0755'
      action :create
      recursive true
    end
  end
end

action :enable do
  action_install
  service "filestat_exporter_#{new_resource.name}" do
    action :enable
  end
end

action :start do
  service "filestat_exporter_#{new_resource.name}" do
    action :start
  end
end

action :disable do
  service "filestat_exporter_#{new_resource.name}" do
    action :disable
  end
end

action :stop do
  service "filestat_exporter_#{new_resource.name}" do
    action :stop
  end
end
