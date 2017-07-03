# encoding: utf-8
# frozen_string_literal: true

require_relative '../centos'

describe 'resources::ec2_net_utils::centos::7_3_1611' do
  include_context 'resources::ec2_net_utils::centos'

  let(:platform_version) { '7.3.1611' }

  let(:hotplug_support) { false }

  it_behaves_like 'any CentOS platform'
end
