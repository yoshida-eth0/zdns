require 'zdns/ar/model/lookup_sync'

module ZDNS
  module AR
    module Model
      class NsRecord < ActiveRecord::Base
        include LookupSync::Record

        attr_accessible :soa_record_id
        attr_accessible :name
        attr_accessible :ttl
        attr_accessible :nsdname

        belongs_to :soa_record

        RDATA_FIELDS = [:nsdname]
      end
    end
  end
end
