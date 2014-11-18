require 'sinatra'
require 'sinatra/activerecord'
require_relative '../config/environments'

class Income < ActiveRecord::Base
end
