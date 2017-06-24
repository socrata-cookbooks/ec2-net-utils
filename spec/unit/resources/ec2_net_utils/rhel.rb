# encoding: utf-8
# frozen_string_literal: true

require_relative '../ec2_net_utils'

shared_context 'resources::ec2_net_utils::rhel' do
  include_context 'resources::ec2_net_utils'

  let(:dev_config_dir) { '/etc/sysconfig/network-scripts' }
  let(:network_scripts_dir) { '/etc/sysconfig/network-scripts' }
  let(:dev_config_path) { '/etc/sysconfig/network-scripts/ifcfg-${INTERFACE}' }
  let(:dev_route_path) { '/etc/sysconfig/network-scripts/route-${INTERFACE}' }
  let(:dev_route6_path) { '/etc/sysconfig/network-scripts/route6-${INTERFACE}' }
  let(:dev_dhclient_path) { '/etc/dhcp/dhclient-${INTERFACE}.conf' }
  let(:dev_config_format) do
    <<-EOH.gsub(/^ +/, '').strip
      # This file is automatically generated.
      # Any changes to it will be overwritten.
      DEVICE=${INTERFACE}
      BOOTPROTO=dhcp
      ONBOOT=yes
      TYPE=Ethernet
      USERCTL=yes
      PEERDNS=no
      IPV6INIT=yes
      DHCPV6C=yes
      DHCPV6C_OPTIONS=-nw
      PERSISTENT_DHCLIENT=yes
      HWADDR=${HWADDR}
      DEFROUTE=no
      EC2SYNC=yes
    EOH
  end
  let(:ec2dhcp_script_path) { '/etc/dhcp/dhclient.d/ec2dhcp.sh' }
  let(:ec2ifscan_dev_path) { '/etc/sysconfig/network-scripts/ifcfg-${dev##*/}' }

  shared_examples_for 'any RHEL platform' do
    it_behaves_like 'any platform'

    context 'the :install action' do
      include_context description

      context 'all default properties' do
        include_context description

        it 'does not add Debian hooks into the ec2dhcp file' do
          c = <<-EOH.gsub(/^ {12}/, '').strip
            # Platforms that support dhclient.d scripts will call the above methods on
            # their own, but ones where we have to use exit hooks need some extra help.
            if [ "$reason" = "RELEASE" ]; then
              ec2dhcp_restore
              logger -t ec2net "[ec2dhcp] Released interface $INTERFACE: $?"
            elif [ "$reason" = "BOUND" ] || [ "$reason" = "REBOOT" ] || [ "$reason" = "RENEW" ] || [ "$reason" = "REBIND" ] ; then
              ec2dhcp_config
              logger -t ec2net "[ec2dhcp] Configured interface $INTERFACE: $?"
            else
              logger -t ec2net "[ec2dhcp] No action for interface $INTERFACE on reason $reason"
            fi
          EOH
          expect(chef_run).to_not render_file(ec2dhcp_script_path)
            .with_content(c)
        end

        it 'adds workarounds for a lack of hotplug support if appropriate' do
          f = '/etc/udev/rules.d/53-ec2-network-interfaces.rules'
          [
            Regexp.new('^ACTION=="add", SUBSYSTEM=="net", ' \
                       'KERNEL=="eth\\*", ' \
                       'RUN\\+="/sbin/ec2ifup \\$env{INTERFACE}"$'),
            Regexp.new('^ACTION=="remove", SUBSYSTEM=="net", ' \
                       'KERNEL=="eth\\*", ' \
                       'RUN\\+="/sbin/ec2ifdown \\$env{INTERFACE}"$')
          ].each do |r|
            if platform_version.to_i >= 7
              expect(chef_run).to render_file(f).with_content(r)
            else
              expect(chef_run).to_not render_file(f).with_content(r)
            end
          end
        end
      end
    end
  end
end
