require 'zdns/packet/type'
require 'zdns/packet/class'
require 'zdns/packet/utils'

module ZDNS
  class Packet
    module RR
      class Base
        include Utils

        def initialize(name, ttl, rdata={})
          @name = name.to_s
          @ttl = ttl.to_i

          rdata.each_pair do |key,value|
            setter = "#{key}="
            send(setter, rdata[key]) if respond_to?(setter)
          end
        end

        def build_rdata(result)
          raise ZDNS::AbstractError, "#{self.class.name}.build_rdata is abstract method"
        end

        def to_bin(result)
          name_bin = compress_domain(result, self.name)
          rdata_bin = build_rdata(result)

          result + name_bin + [self.type.to_i, self.cls.to_i, self.ttl.to_i, rdata_bin.length].pack("n2Nn") + rdata_bin
        end

        def to_hash
          instance_variables.inject({}) {|h,k|
            h.update({k.to_s.sub("@", "") => instance_variable_get(k)})
          }
        end

        def ==(obj)
          self.class==obj.class && self.to_hash.reject{|k,v| v.nil?}==obj.to_hash.reject{|k,v| v.nil?}
        end

        class << self
          def parse_rdata
            raise ZDNS::AbstractError, "#{self.name}.parse_rdata is abstract method"
          end
        end
      end
    end
  end
end
