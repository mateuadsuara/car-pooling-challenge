$: << File.expand_path('lib/', File.dirname(__FILE__))

require 'rack'
require 'web/api'

run Web::Api.new()
