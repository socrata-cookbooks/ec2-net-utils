# encoding: utf-8
# frozen_string_literal: true

require_relative 'spec_helper'

describe command('ethtool eth1') do
  it 'indicates eth1 is up' do
    expect(subject.exit_status).to eq(0)
  end
end
