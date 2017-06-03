# encoding: utf-8
# frozen_string_literal: true

require_relative '../ubuntu'

describe 'resources::ec2_net_utils::ubuntu::16_04' do
  include_context 'resources::ec2_net_utils::ubuntu'

  let(:platform_version) { '16.04' }

  it_behaves_like 'any Ubuntu platform'
end
