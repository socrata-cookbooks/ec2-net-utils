# encoding: utf-8
# frozen_string_literal: true

require_relative '../centos'

describe 'resources::ec2_net_utils::centos::6_9' do
  include_context 'resources::ec2_net_utils::centos'

  let(:platform_version) { '6.9' }

  it_behaves_like 'any CentOS platform'
end
