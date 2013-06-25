require 'zdns/ar/model/lookup_sync'

module ZDNS
  module AR
    module Model
      class SoaRecord < ActiveRecord::Base
        include LookupSync::Zone

        attr_accessible :name
        attr_accessible :ttl
        attr_accessible :mname
        attr_accessible :rname
        attr_accessible :serial
        attr_accessible :refresh
        attr_accessible :retry
        attr_accessible :expire
        attr_accessible :minimum

        has_many :a_records
        has_many :ns_records
        has_many :cname_records
        has_many :mx_records
        has_many :txt_records
        has_many :aaaa_records

        RDATA_FIELDS = [:mname, :rname, :serial, :refresh, :retry, :expire, :minimum]

        def to_bind
          lines = []

          lines << "$TTL #{self.ttl}"
          lines << ""

          lines << "; SOA Record"
          lines << "#{self.lookup_fqdn} IN SOA #{self.mname} #{self.rname} ("
          lines << sprintf("    %11d ; Serial Number", self.serial)
          lines << sprintf("    %11d ; Refresh Time", self.refresh)
          lines << sprintf("    %11d ; Retry Time", self.retry)
          lines << sprintf("    %11d ; Expire Time", self.expire)
          lines << sprintf("    %11d ; Cache Time", self.minimum)
          lines << ")"

          self.class.reflections.keys.each do |key|
            lines << ""
            record_type = key.to_s.sub("_records", "").upcase
            lines << "; #{record_type} Records"
            self.send(key).each do |record|
              lines << record.to_bind
            end
          end

          lines.join("\n")
        end
      end
    end
  end
end
