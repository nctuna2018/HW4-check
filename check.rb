#!/usr/bin/env ruby
require 'fileutils'
Dir['./checks/*.rb'].each do |rb|
	require rb
end

module Resolver
	def self.query(host, type = :A)
		`dig #{type} "#{host}" | grep -v ';' | grep "#{host}" | grep #{type}`.each_line.map do |line|
			line.split[-1]
		end
	end
end

class Checker
  def initialize(id, private_key)
		@id = id
		@base_domain = "#{id}.nasa"
		@private_key = private_key
		@checkpoint_base = File.join(__dir__, 'points', @id)
		FileUtils.mkdir_p(@checkpoint_base)
  end

	def check!
		puts "Checking #{@base_domain}... (key: #{@private_key})"
	end

	def pass!(checkpoint)
		puts "> Pass checkpoint: #{checkpoint}"
		FileUtils.touch(File.join(@checkpoint_base, checkpoint.to_s.downcase))
	end

	prepend CheckDns
	prepend CheckStarttls
	prepend CheckAccount
	prepend CheckGreylist
	prepend CheckAlias
	prepend CheckIngoingFilter
	prepend CheckRewrite
	prepend CheckOutgoingFilter
	prepend CheckOpenRelay
end

Checker.new(ARGV[1] || 'tzute', ARGV[2] || '').check!
