# encoding: utf-8
# frozen_string_literal: true

require_relative 'spec_helper'

describe command('ip route show') do
  it 'includes the normal route for eth1' do
    r = Regexp.new('^[0-9]+(\.[0-9]+){3}/[0-9]+ dev eth1  proto kernel  ' \
                   'scope link  src [0-9]+(\.[0-9]+){3} $')
    expect(subject.stdout).to match(r)
  end

  it 'includes the extra metric route for eth1' do
    r = /^default via [0-9]+(\.[0-9]+){3} dev eth1  metric 10001 $/
    expect(subject.stdout).to match(r)
  end
end

describe command('ip route show table 10001') do
  it 'has a default route out eth1' do
    r = /^default via [0-9]+(\.[0-9]+){3} dev eth1 $/
    expect(subject.stdout).to match(r)
  end
end

describe command('ip rule show') do
  it 'has a rule mapping the eth1 IP to the new route table' do
    r = /^32765:\tfrom [0-9]+(\.[0-9]+){3} lookup 10001 $/
    expect(subject.stdout).to match(r)
  end
end

describe command('curl --interface eth1 --connect-timeout 3 ' \
                 'https://www.google.com') do
  it 'indicates a successful route out of eth1' do
    expect(subject.exit_status).to eq(0)
  end
end
