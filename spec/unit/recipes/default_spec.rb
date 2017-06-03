# encoding: utf-8
# frozen_string_literal: true

require_relative '../../spec_helper'

describe 'ec2-net-utils::default' do
  let(:platform) { { platform: 'ubuntu', version: '16.04' } }
  let(:runner) { ChefSpec::ServerRunner.new(platform) }
  let(:chef_run) { runner.converge(described_recipe) }

  it 'installs the ec2-net-utils scripts' do
    expect(chef_run).to install_ec2_net_utils('default')
  end
end
