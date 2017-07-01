# encoding: utf-8
# frozen_string_literal: true

#
# Cookbook Name:: ec2-net-utils
# Library:: resource/ec2-net-utils/debian
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

require_relative '../ec2_net_utils'

class Chef
  class Resource
    class Ec2NetUtils < Resource
      # A Debian implementation of the ec2_net_utils resource.
      #
      # @author Jonathan Hartman <jonathan.hartman@socrata.com>
      class Debian < Ec2NetUtils
        resource_name :ec2_net_utils_debian
        provides :ec2_net_utils, platform_family: 'debian'

        #
        # Ensure the APT cache is up to date if we'll be installing udev or
        # curl.
        #
        action :install do
          apt_update 'ec2-net-utils' do
            action :nothing
            subscribes :periodic, 'package[udev]', :before
            subscribes :periodic, 'package[curl]', :before
          end
          super()
        end

        #
        # Debian systems support network device hotplugging.
        #
        def hotplug_support
          true
        end

        #
        # Debian configs also use their pre- and post- scripts to manage their
        # route and dhclient configs.
        #
        def dev_config_format
          <<-EOH.gsub(/^ +/, '').strip
            # This file is automatically generated.
            # Any changes to it will be overwritten.
            auto ${INTERFACE}
            allow-hotplug ${INTERFACE}
            iface ${INTERFACE} inet dhcp

            pre-up echo 'interface "${INTERFACE}" { supersede dhcp-server-identifier 255.255.255.255; }' >> /etc/dhcp/dhclient.conf

            post-up ip route add default via ${gateway} dev ${INTERFACE} table ${RTABLE}
            post-up ip route add default via ${gateway} dev ${INTERFACE} metric ${RTABLE}

            post-down sed -i '/^interface "${INTERFACE}" { supersede dhcp-server-identifier 255.255.255.255; }$/d' /etc/dhcp/dhclient.conf
          EOH
        end

        #
        # Debian network configs go in interfaces.d.
        #
        def dev_config_path
          "#{dev_config_dir}/${INTERFACE}.cfg"
        end

        #
        # The route rules in Debian are set up in the networking config.
        #
        def dev_route_path
          nil
        end

        #
        # ...ditto.
        #
        def dev_route6_path
          nil
        end

        #
        # Debian's dhclient doesn't support individual device configs.
        #
        def dev_dhclient_path
          nil
        end

        #
        # Debian network device configs live in the interfaces.d dir.
        #
        def ec2ifscan_dev_path
          "#{dev_config_dir}/${dev##*/}.cfg"
        end

        #
        # On Debian systems, DHCP helper scripts must *not* end in .sh.
        #
        def ec2dhcp_script_path
          '/etc/dhcp/dhclient-exit-hooks.d/ec2dhcp'
        end

        #
        # There is no network-scripts dir in Debian so let's use /etc/network.
        #
        def network_scripts_dir
          '/etc/network'
        end

        #
        # Debian has an interfaces.d dir for device configs.
        #
        def dev_config_dir
          ::File.join(network_scripts_dir, 'interfaces.d')
        end
      end
    end
  end
end
