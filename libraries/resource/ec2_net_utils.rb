# encoding: utf-8
# frozen_string_literal: true

#
# Cookbook Name:: ec2-net-utils
# Library:: resource/ec2-net-utils
#
# Copyright 2017, Socrata, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/resource'

class Chef
  class Resource
    # A main Chef resource for installing the EC2 net utils.
    #
    # @author Jonathan Hartman <jonathan.hartman@socrata.com>
    class Ec2NetUtils < Resource
      default_action :install

      #
      # Drop off the files in the correct locations.
      #
      action :install do # rubocop:disable Metrics/BlockLength
        %w[udev curl].each { |p| package p }
        # TODO: Will this harm anything if the driver isn't installed?
        cookbook_file '/etc/modprobe.d/ixgbevf.conf'
        %w[rule_generator.functions write_net_rules].each do |f|
          cookbook_file ::File.join('/lib/udev', f) do
            cookbook 'ec2-net-utils'
            mode '0755'
          end
        end

        template ::File.join(network_scripts_dir, 'ec2net-functions') do
          cookbook 'ec2-net-utils'
          mode '0755'
          variables(dev_config_path: dev_config_path,
                    dev_route_path: dev_route_path,
                    dev_route6_path: dev_route6_path,
                    dev_dhclient_path: dev_dhclient_path,
                    dev_config_format: dev_config_format)
        end

        %w[ec2ifdown ec2ifup].each do |f|
          template ::File.join('/sbin', f) do
            cookbook 'ec2-net-utils'
            mode '0755'
            variables(network_scripts_dir: network_scripts_dir)
          end
        end

        template '/sbin/ec2ifscan' do
          cookbook 'ec2-net-utils'
          mode '0755'
          variables(ec2ifscan_dev_path: ec2ifscan_dev_path)
        end

        %w[ec2ifdown ec2ifscan ec2ifup].each do |f|
          cookbook_file "/usr/share/man/man8/#{f}.8.gz" do
            cookbook 'ec2-net-utils'
          end
        end

        template ec2dhcp_script_path do
          cookbook 'ec2-net-utils'
          source 'ec2dhcp.sh.erb'
          mode '0755'
          variables(network_scripts_dir: network_scripts_dir,
                    exit_hooks: ::File.dirname(ec2dhcp_script_path)
                                      .end_with?('/dhclient-exit-hooks.d'))
        end

        # TODO: /etc/init/elastic-network-interfaces.conf

        template '/etc/udev/rules.d/53-ec2-network-interfaces.rules' do
          cookbook 'ec2-net-utils'
          variables(network_scripts_dir: network_scripts_dir,
                    hotplug_support: hotplug_support)
        end

        cookbook_file '/etc/udev/rules.d/75-persistent-net-generator.rules' do
          cookbook 'ec2-net-utils'
        end

        template ::File.join(network_scripts_dir, 'ec2net.hotplug') do
          cookbook 'ec2-net-utils'
          mode '0755'
          variables(network_scripts_dir: network_scripts_dir)
        end
      end

      #
      # Delete all the files we dropped off in the create action. We can't
      # uninstall the packages since they're very likely in use by other parts
      # of the system.
      #
      action :remove do
        [
          ::File.join(network_scripts_dir, 'ec2net.hotplug'),
          '/etc/udev/rules.d/75-persistent-net-generator.rules',
          '/etc/udev/rules.d/53-ec2-network-interfaces.rules',
          ec2dhcp_script_path,
          ::File.join(network_scripts_dir, 'ec2net-functions'),
          '/etc/modprobe.d/ixgbevf.conf'
        ].each { |f| file(f) { action :delete } }

        %w[rule_generator.functions write_net_rules].each do |f|
          file("/lib/udev/#{f}") { action :delete }
        end

        %w[ec2ifdown ec2ifscan ec2ifup].each do |f|
          file("/usr/share/man/man8/#{f}.8.gz") { action :delete }
          file("/sbin/#{f}") { action :delete }
        end
      end
    end
  end
end
