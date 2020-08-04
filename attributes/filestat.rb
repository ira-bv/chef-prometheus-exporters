default['prometheus_exporters']['filestat']['version'] = '0.3.1'
default['prometheus_exporters']['filestat']['url'] = "https://github.com/michael-doubez/filestat_exporter/releases/download/v#{node['prometheus_exporters']['filestat']['version']}/filestat_exporter-v#{node['prometheus_exporters']['filestat']['version']}.linux-amd64.tar.gz"
default['prometheus_exporters']['filestat']['checksum'] = '7834fa0bea6114c3368d05e85b859c2da30d7dd3f8c873efd2e83b9bf14428f5'

default['prometheus_exporters']['filestat']['file_path'] = '/var/lib/filestat_exporter/textfile_collector'

default['prometheus_exporters']['filestat']['port'] = 9202
default['prometheus_exporters']['filestat']['user'] = 'root'
