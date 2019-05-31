# frozen_string_literal: true

Dir.glob("#{__dir__}/*.rb").each do |file|
  require file
end

require_relative 'pages/init.rb'