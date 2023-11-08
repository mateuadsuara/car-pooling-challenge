$: << File.expand_path('lib/', File.dirname(__FILE__))

require 'rack'
require 'web/api'
require 'car_pooling/service'

run Web::Api.new(CarPooling::Service)
