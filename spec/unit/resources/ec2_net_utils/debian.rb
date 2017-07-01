# encoding: utf-8
# frozen_string_literal: true

require_relative '../ec2_net_utils'

shared_context 'resources::ec2_net_utils::debian' do
  include_context 'resources::ec2_net_utils'

  let(:platform) { 'debian' }

  let(:dev_config_dir) { '/etc/network/interfaces.d' }
  let(:network_scripts_dir) { '/etc/network' }
  let(:dev_config_path) { '/etc/network/interfaces.d/${INTERFACE}.cfg' }
  let(:dev_route_path) { nil }
  let(:dev_route6_path) { nil }
  let(:dev_dhclient_path) { nil }
  let(:dev_config_format) do
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
  let(:ec2dhcp_script_path) { '/etc/dhcp/dhclient-exit-hooks.d/ec2dhcp' }
  let(:ec2ifscan_dev_path) { '/etc/network/interfaces.d/${dev##*/}.cfg' }

  shared_examples_for 'any Debian platform' do
    it_behaves_like 'any platform'

    context 'the :install action' do
      include_context description

      context 'all default properties' do
        include_context description

        it 'ensures APT is up to date if a package is to be installed' do
          r = chef_run.apt_update('ec2-net-utils')
          expect(r).to do_nothing
          expect(r).to subscribe_to('package[udev]').on(:periodic).before
          expect(r).to subscribe_to('package[curl]').on(:periodic).before
        end

        it 'adds Debian hooks into the ec2dhcp file' do
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
          expect(chef_run).to render_file(ec2dhcp_script_path).with_content(c)
        end

        it 'does not add workarounds for a lack of hotplug support' do
          f = '/etc/udev/rules.d/53-ec2-network-interfaces.rules'
          [
            Regexp.new('^ACTION=="add", SUBSYSTEM=="net", ' \
                       'KERNEL=="eth\\*", ' \
                       'RUN\\+="/sbin/ec2ifup \\$env{INTERFACE}"$'),
            Regexp.new('^ACTION=="remove", SUBSYSTEM=="net", ' \
                       'KERNEL=="eth\\*", ' \
                       'RUN\\+="/sbin/ec2ifdown \\$env{INTERFACE}"$')
          ].each do |r|
            expect(chef_run).to_not render_file(f).with_content(r)
          end
        end
      end
    end
  end
end
