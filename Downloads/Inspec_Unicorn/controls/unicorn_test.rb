# encoding:utf-8
# Copyright 2018, Viswanath K
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#
#
#
#
# Unless required by applicable law or agreed to in writing,software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# author: Viswanath K
          
title 'Unicorn server config'


#OS SPECIFICATIONS
 OS_NAME =os[:name]
 OS_FAMILY = os[:family]
 OS_VERSION = os[:release]
 OS_ARCH =os[:arch]
  
#RUBY SPECIFICATIONS
RUBY_SPEC =command('ruby -v').stdout

if OS_NAME =='ubuntu' && OS_FAMILY == 'debian' && OS_VERSION =='16.04' && OS_ARCH =='x86_64' &&
RUBY_SPEC == "ruby 2.4.3p205 (2017-12-14 revision 61247) [x86_64-linux]\n"
then 

control 'unicorn_install' do
impact 1.0
 title 'VERIFYING THE INSTALLATION OF UNICORN'
 desc 'Checking the process of installing unicorn'
=begin
describe service('unicorn_appname') do
 it {should be_installed}
 it {should be_enabled }
 it {should be_running }
end
=end
describe service('unicorn') do
 it {should be_installed}
 it {should be_enabled }
 it {should be_running } 
 end 
describe gem('unicorn') do
 it { should be_installed }
  its('version') { should eq '5.3.1' }
end
end


# Determine all required paths
unicorn_path       = '/lib/systemd/system'
unicorn_service    = File.join(unicorn_path, 'unicorn.service') 
control 'unicorn_service' do
impact 1.0
title 'VERIFYING THE SETTINGS OF UNICORN.SERVICE FILE'
desc 'CHECKING THE CONFIGURATION OF UNICORN.SERVICE FILE'
describe file(unicorn_service) do
    it {should be_file}
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should  be_readable.by('others') }
    it { should_not be_writable.by('others') }
    it { should_not be_executable.by('others') }
end
title 'Parsing the unicorn.service file to ensure proper settings for the application to run'
desc 'Checking the settings of unicorn.service file for proper execution of the application'
describe file(unicorn_service) do
its ('content') { should match 'User=viswak7'}
its ('content'){ should match 'WorkingDirectory=/home/viswak7/appname'}
its ('content'){ should match 'Environment=RAILS_ENV=production'}
its ('content'){ should match 'PIDFile=/home/viswak7/appname/shared/pids/unicorn.pid'}
its ('content'){ should match 'ExecStart=/usr/bin/bundle exec "unicorn_rails -D -c /home/viswak7/appname/config/unicorn.rb -E production"'}
end
end
#options to parse unicorn.service file
#options ={
 #  assignment_regex: /^\s*([^:]*?)\s*\=\s*(.*?)\s*$/ 
#}


# DEPENDENCY CHECK FOR UNICORN
#RUNTIME DEPENDENCIES FOR UNICORN : kgio ~> 2.6; raindrops ~> 0.7
#DEVELOPMENT DEPENDENCIES: rack >= 0;test-unit ~> 3.0 
control 'unicorn_dependency' do
impact 1.0
title 'Verify the existence of GEMS'
desc 'CHECKING THE INSTALLATION OF RUNTIME DEPENDENCIES GEMS'
desc 'VERIFYING THE INSTALLATION OF KGIO'
describe gem('kgio') do
  it { should be_installed }
  its('version') { should eq '2.11.1' }
end
desc 'VERIFYING THE INSTALLATION OF RAINDROPS'
describe gem('raindrops') do
  it { should be_installed }
  its('version') { should eq '0.19.0' }
end

desc 'CHECKING THE INSTALLATION OF DEVELOPMENT DEPENDENCIES GEMS'
desc 'VERIFYING THE INSTALLATON OF RACK'
describe gem('rack') do
  it { should be_installed }
  its('version') { should > '0' }
end
desc 'VERFYING THE INSTALLATION OF TEST_UNIT'
describe gem('test-unit') do
  it { should be_installed }
  its('version') { should > '3.0' }
end
end	



#CHECKING NGINX SERVER 
#NGINX WITH UNICORN
#CHECKING NGINX CONFIGURATION WITH RESPECT TO UNICORN
# determine all required paths
nginx_path      = '/etc/nginx'
nginx_conf      = File.join(nginx_path, 'nginx.conf')
nginx_confd     = File.join(nginx_path, 'conf.d')
nginx_enabled   = File.join(nginx_path, 'sites-enabled')
nginx_available = File.join(nginx_path, 'sites-available')
nginx_default   = File.join(nginx_available, 'default')


# 'options' to help the usage of 'parse_config_file' inspec resource
options = {
  assignment_regex: /^\s*([^:]*?)\s*\ \s*(.*?)\s*;$/
}


#options_add_header = {
  #assignment_regex: /^\s*([^:]*?)\s*\ \s*(.*?)\s*;$/,
  #multiple_values: true
#}
control 'nginx_config_settings' do
impact 1.0
title 'Ensure worker process is running as non-privileged user'
desc 'The NGINX worker processes should run as non-privileged user.In case of compromise of the process,an attacker has full access to the system.'
=begin
 describe user(nginx_lib.valid_users) do
    it { should exist }
  end
describe parse_config_file(nginx_conf, options) do
    its('user') { should eq nginx_lib.valid_users }
  end
=end
describe parse_config_file(nginx_conf, options) do
    its('group') { should_not eq 'root' }
  end
describe parse_config_file(nginx_default,options) do
    its('listen') { should eq "80"}
end
end
control 'nginx_config_file_check' do
  impact 1.0
  title 'Check NGINX config file owner, group and permissions.'
  desc 'The NGINX config file should owned by root, only be writable by owner and not write- and readable by others.'
  describe file(nginx_conf) do
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should  be_readable.by('others') }
    it { should_not be_writable.by('others') }
    it { should_not be_executable.by('others') }
  end
end
control 'nginx_default' do
  impact 1.0
  title 'Verify the existane of Nginx default files'
  desc 'Remove the default nginx config files.'
  describe file(File.join(nginx_confd, 'default.conf')) do
    it { should_not be_file }
  end
end
control 'nginx_sites_available_and_nginx_sites_enabled' do
impact 1.0
title 'Verify the properties of sites-available and sites-enabled'
desc 'Checking for default files'
describe file(File.join(nginx_available,'default'))do
it { should be_file}
end
describe file(File.join(nginx_enabled, 'default'))do
its('type') { should cmp 'symlink' }
it { should be_symlink }
it { should_not be_file }
it { should_not be_directory }
       #CHECKING PERMISSIONS FOR THE FILE    
           it { should be_owned_by 'root' }
           it { should be_grouped_into 'root' }
           it { should  be_readable.by('others') }
           it { should_not be_writable.by('others') }
           it { should_not be_executable.by('others') }
end
end
control 'nginx_port'do
impact 1.0
title 'VERIFY THE LISTENING OF PORT: IF THE ADDRESS OF THE PORT IS 0.0.0.0 IT MEANS IT IS ACCESSIBLE BY ALL INTERFACES.SECURE IT USING SSH KEYS'
desc 'Checking the properties of nginx_port'
desc 'For Checking the running process on the particular port login as root user'
describe port(80) do
it {should be_listening}
its('addresses') { should include '0.0.0.0' }
its('addresses') { should include '127.0.0.1' }
its('protocols') {should include 'tcp'}
its('processes') {should include 'nginx'}
end
end


#CHECKING THE CONFIGURATION FILE FOR UNICORN SERVER WITH NGINX
#THIS INCLUDES CHECKING OF COMPONENTS SUCH AS #working_directory,shared_dir,app_dir,worker_processes,preload_app,timeout,listen,stderr_path,
#stdout_path,pid
 
#required paths for configuartion of unicorn
user=File.open('/etc/hostname','r')
if user
content =user.read
user_name=content.split('-')
system_user=user_name[0]
unicorn_appname ='/home/' + system_user +'/appname/config'
unicorn_rb   =File.join(unicorn_appname,'unicorn.rb')

control 'unicorn_config' do
impact 1.0
title 'VERIFYING THE SETTINGS OF UNICORN CONFIG FILE'
desc 'Checking for the properties and thier values in the unicorn.rb file'
describe file(unicorn_rb) do
    it {should be_file}
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should  be_readable.by('others') }
    it { should_not be_writable.by('others') }
    it { should_not be_executable.by('others') }
end
desc  'VERIFYING THE PROPERTIES OF UNICORN.RB FILE,FUNDAMENTAL PROPERTIES ARE NEEDED FOR DEPLOYING RAILS APPLICATION WITH UNICORN AND NGINX'
desc 'Checking the fundamental properties needed for configuring the unicorn server'

desc 'WORKER_PROCESSES:This sets the number of worker processes to launch'
describe file(unicorn_rb) do
 its ('content') {should match 'worker_processes 2'}
end

desc 'TIMEOUT:This setting sets the amount of time before a worker times out'
describe file(unicorn_rb) do
 its ('content') {should match 'timeout 30'}
end

desc 'Setting this to true reduces the start up time for starting up the Unicorn worker processes.'
describe file(unicorn_rb) do
 its ('content') {should match 'preload_app true'}
end

desc 'VERIFYING THE SETTING UP OF SOCKET LOCATION AND THE BACKLOG'
describe file(unicorn_rb) do
 its ('content') {should match 'listen "#{shared_dir}/sockets/unicorn.sock"'}
 its ('content') {should match 'backlog => 64'}
end

desc 'VERIFYING THE LOGGING SETTINGS OF UNICORN:stderr path for ERROR LOGS AND stdout path for status logs'
describe file(unicorn_rb) do
its ('content') {should match 'stderr_path "#{shared_dir}/log/unicorn.stderr.log"'}
its ('content') {should match 'stdout_path "#{shared_dir}/log/unicorn.stdout.log"'}
end

desc 'VERIFYING THE SETTING OF MASTER PROGRAM ID LOCATION'
describe file(unicorn_rb) do
its ('content') {should match 'pid "#{shared_dir}/pids/unicorn.pid"'}
end
end
end
#TUNING THE PERFORMANCE OF UNICORN SERVER
#THERE ARE 3 WAYS TO TUNE UNICORN WORKERS FOR EFFICIENT PERFORMANCE  AND ACHIEVE MAXIMUM PERFORMANCE
#1.Using Ruby 2.0 and above gives us a much improved garbage collector that allows us to exploit copy-on-write semantics.
#2.Tuning the various configuration options in config/unicorn.rb.
#3.Using unicorn-worker-killer gem to solve the problem of gracefully by killing and restarting workers when they get too bloated.

# USING RUBY 2.0 AND ABOVE
 
control 'ruby_2.0_and_above' do
impact 5.0
title 'CHECKING THE VERSION OF RUBY INSTALLED.IF RUBY VERSION >= 2.0 THEN THERE IS A MUCH IMPROVED GARBAGE COLLECTOR THAT ALLOWS TO EXPLOIT COPY-ON-WRITE SEMANTICS.IF RUBY VERSION <2.0 THEN IT BECOMES CRITICAL ON MEMORY TERMS FOR DEPLOYING APPLICATIONS USING UNICORN WITH NGINX BECAUSE OF NOT EXPLOITING COPY-ON-WRITE SEMANTIC.'
desc 'If you are using Ruby 1.9, you should seriously consider switching to Ruby 2.0.Ruby 1.9 does not implement Forking and Copy-on-Write (CoW).More accurately, the garbage collection implementation of Ruby 1.9 does not make this possible.Ruby 2.0 fixes this, and can now exploit CoW.'
describe command('ruby -v')do
its ('stdout') {should eq "ruby 2.4.3p205 (2017-12-14 revision 61247) [x86_64-linux]\n"}
its ('stderr') {should eq ''}
its ('exit_status'){should eq 0}
end 
end
# TUNING THE VARIOUS CONFIGURATION  OPTIONS IN CONFIG/UNICORN.RB
# NO OF WORKER_PROCESSES
NO_OF_CORE = command('cat /proc/cpuinfo | grep processor | wc -l').stdout  #tofindnoofcpucores

#FOR THE BEST PRACTICES OF UNICORN IT IS RECOMMENDED TO HAVE [CPU CORE+1] NUMBER OF WORKER_PROCESSES
			 	                       	   					
WORKER_PROCESSESS=NO_OF_CORE.to_i + 1

control 'worker_processes' do
impact 5.0
title 'This sets the number of worker processes to launch.FOR THE BEST PRACTICES OF UNICORN IT IS RECOMMENDED TO HAVE [CPU CORE+1] NUMBER OF WORKER_PROCESSES'
desc 'It is important to know how much memory does one process take.This is so that you can safely budget the amount of workers, in order not to exhaust the RAM'
describe file(unicorn_rb) do
#its ('worker_processes') {should match WORKER_PROCESSESS}
its ('content') {should match 'worker_processes 2'}
end
end

#TIMEOUT SETTING

control 'timeout' do
impact 5.0
title 'This should be set to a small number.Usually 15 to 30 seconds is a reasonable number.'
desc 'This setting sets the amount of time before a worker times out.The reason you want to set a relatively low number is to prevent a long-running request from holding back other requests from being processed.'
describe file(unicorn_rb) do
its ('content') {should match 'timeout 15'}
end
end

#PRELOAD_APP SETTING

control 'preload_app' do
impact 5.0
title 'This should be set to true.Setting this to true reduces the start up time for starting up the Unicorn worker processes.'
desc 'This uses Copy-on-write (CoW) to preload the application before forking other worker processes.'
describe file(unicorn_rb) do
its ('content') {should match 'preload_app true'}
end
end

#BEFORE_FORK and AFTER_FORK SETTING

control 'before_fork and after_fork' do
impact 5.0
title 'special care must be taken such that any sockets (such as database connections) are properly closed and reopened.This can be done by before_fork|,| and after_fork |,|'
desc 'before_fork|,| and after_fork |,| are used for closing and opening connections which reduces the memory consumption partially'
describe file(unicorn_rb) do
its ('content') {should match 'ActiveRecord::Base.connection.disconnect!'}
its ('content') {should match 'ActiveRecord::Base.establish_connection'}
end
end

#UNICORN-WORKER-KILLER GEM
#Enter the Unicorn Worker Killer
#One of the easiest solutions I've come across is the unicorn-worker-killer gem.
#unicorn-worker-killer gem provides automatic restart of Unicorn workers based on 
#1) max number of requests, and
#2) process memory size (RSS), without affecting any requests. 
#This will greatly improve the site's stability by avoiding unexpected memory exhaustion at the application nodes.
#Step 1:
#Add unicorn-worker-killer to your Gemfile. Put this below the unicorn gem.
=begin
group :production do 
  gem 'unicorn'
  gem 'unicorn-worker-killer'
end
=end

#Step 2:
#Run bundle install.

#Step 3:
#Here comes the fun part. Locate and open your config.ru file
=begin
# --- Start of unicorn worker killer code ---

if ENV['RAILS_ENV'] == 'production' 
  require 'unicorn/worker_killer'

  max_request_min =  500
  max_request_max =  600

  # Max requests per worker
  use Unicorn::WorkerKiller::MaxRequests, max_request_min, max_request_max

  oom_min = (240) * (1024**2)
  oom_max = (260) * (1024**2)

  # Max memory size (RSS) per worker
  use Unicorn::WorkerKiller::Oom, oom_min, oom_max
end

# --- End of unicorn worker killer code ---

require ::File.expand_path('../config/environment',  __FILE__)
run YourApp::Application
=end
#First, we check that we are in the production environment. If so, we will go ahead and execute #the code that follows.
#unicorn-worker-killer kills workers given 2 conditions: Max requests and Max memory.


end


