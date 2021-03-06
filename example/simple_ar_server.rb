#!/usr/bin/ruby

$LOAD_PATH << File.expand_path("../lib", File.dirname(__FILE__))

require 'zdns'
require 'zdns/ar'

# start server
config = {
  :host => '0.0.0.0',
  :port => 53,
}
db_config ={
  :adapter => "sqlite3",
  :database  => "/tmp/zdns_simple_ar_server.db",
}
server = ZDNS::AR::Server.new(config, db_config)

server.start {
  # create sample data
  ActiveRecord::Base.logger = Logger.new(STDOUT)

  # soa record
  soa = ZDNS::AR::Model::SoaRecord.where(
    :name => "example.com.",
    :ttl => 3600,
    :mname => "ns.example.com.",
    :rname => "root.example.com.",
    :serial => 20130606,
    :refresh => 14400,
    :retry => 3600,
    :expire => 604800,
    :minimum => 7200,
  ).first_or_create!

  # a record
  a_root = ZDNS::AR::Model::ARecord.where(
    :soa_record_id => soa.id,
    :name => "@",
    :ttl => nil,
    :address => "192.168.1.80",
    :enable_ptr => true,
  ).first_or_create!

  a_www = ZDNS::AR::Model::ARecord.where(
    :soa_record_id => soa.id,
    :name => "www",
    :ttl => 120,
    :address => "192.168.1.80",
    :enable_ptr => true,
  ).first_or_create!

  # aaaa record
  aaaa_root = ZDNS::AR::Model::AaaaRecord.where(
    :soa_record_id => soa.id,
    :name => "@",
    :ttl => nil,
    :address => "2001:db8::80",
    :enable_ptr => true,
  ).first_or_create!

  aaaa_www = ZDNS::AR::Model::AaaaRecord.where(
    :soa_record_id => soa.id,
    :name => "www",
    :ttl => 120,
    :address => "2001:db8::80",
    :enable_ptr => true,
  ).first_or_create!

  # cname record
  cname = ZDNS::AR::Model::CnameRecord.where(
    :soa_record_id => soa.id,
    :name => "www2",
    :ttl => 120,
    :cname => "www.example.com.",
  ).first_or_create!

  # ns record
  a_ns = ZDNS::AR::Model::ARecord.where(
    :soa_record_id => soa.id,
    :name => "ns",
    :ttl => 120,
    :address => "192.168.1.53",
    :enable_ptr => true,
  ).first_or_create!

  aaaa_ns = ZDNS::AR::Model::AaaaRecord.where(
    :soa_record_id => soa.id,
    :name => "ns",
    :ttl => 120,
    :address => "2001:db8::53",
    :enable_ptr => true,
  ).first_or_create!

  ns = ZDNS::AR::Model::NsRecord.where(
    :soa_record_id => soa.id,
    :name => "@",
    :ttl => nil,
    :nsdname => "ns.example.com.",
  ).first_or_create!

  # mx record
  a_mx = ZDNS::AR::Model::ARecord.where(
    :soa_record_id => soa.id,
    :name => "mx",
    :ttl => 120,
    :address => "192.168.1.25",
    :enable_ptr => true,
  ).first_or_create!

  aaaa_mx = ZDNS::AR::Model::AaaaRecord.where(
    :soa_record_id => soa.id,
    :name => "mx",
    :ttl => 120,
    :address => "2001:db8::25",
    :enable_ptr => true,
  ).first_or_create!

  mx = ZDNS::AR::Model::MxRecord.where(
    :soa_record_id => soa.id,
    :name => "@",
    :ttl => 120,
    :preference => 10,
    :exchange => "mx.example.com.",
  ).first_or_create!

  # txt record
  txt = ZDNS::AR::Model::TxtRecord.where(
    :soa_record_id => soa.id,
    :name => "@",
    :ttl => 120,
    :txt_data => "v=spf1 +ip4:192.168.1.25/32 -all",
  ).first_or_create!
}
