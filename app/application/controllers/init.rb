# frozen_string_literal: true

folders = %w[route_helper routes lib]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end

Dir.glob("#{__dir__}/*.rb").each do |file|
  require file
end
