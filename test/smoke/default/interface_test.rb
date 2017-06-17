# encoding: utf-8
# frozen_string_literal: true

require_relative 'spec_helper'

describe command('ethtool eth1') do
  it 'indicates eth1 is up' do
    expect(subject.exit_status).to eq(0)
  end
end

describe command('ip a') do
  it 'shows eth1 has grabbed an IP address' do
    r = Regexp.new('^ +inet [0-9]+(\.[0-9]+){3}/[0-9]+ brd ' \
                   '[0-9]+(\.[0-9]+){3} scope global eth1$')
    expect(subject.stdout).to match(r)
  end
end

describe file('/etc/dhcp/dhclient.conf') do
  it 'makes eth1 use broadcast for its DHCP requests' do
    r = Regexp.new('^interface "eth1" { supersede dhcp-server-identifier ' \
                   '255\.255\.255\.255; }$')
    expect(subject.content).to match(r)
  end
end

describe file('/etc/udev/rules.d/70-persistent-net.rules') do
  it 'contains a rule for eth1' do
    r = Regexp.new('^SUBSYSTEM=="net", ACTION=="add", DRIVERS=="\\?\\*", ' \
                   "ATTR\\{address\\}==\"[0-9a-f](:[0-9a-f]){5}\", " \
                   'KERNEL=="eth\\*", NAME="eth1"$')
    expect(subject.content).to match(r)
  end
end
