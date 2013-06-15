require 'tmpdir'
require 'active_support/core_ext'

module ZDNS
  class Config < Hash
    DEFAULT_CONFIG = {
      :server => {
        :host => '0.0.0.0',
        :port => 53,
        :activerecord => {
          :adapter => "sqlite3",
          :database  => "/usr/local/zdns/zdns.db",
        }
      },
      :daemon => {
        :log_file => "/usr/local/zdns/zdns.log",
        :pid_file => "/usr/local/zdns/zdns.pid",
        :sync_log => true,
        :working_dir => Dir.tmpdir,
      }
    }

    def initialize
      super
      self.update(DEFAULT_CONFIG)
    end

    def load(hash)
      hash = hash.dup

      hash.symbolize_keys!
      hash[:server].symbolize_keys! rescue nil
      hash[:server][:activerecord].symbolize_keys! rescue nil
      hash[:daemon].symbolize_keys! rescue nil

      self.deep_merge!(hash)
    end

    def load_file(file_path, type=nil)
      # type
      unless type
        type = "yaml"
        m = file_path.downcase.match(/\.([a-z]+)$/)
        if m
          type = m[1]
        end
      end

      load_method = "load_#{type}"
      if respond_to?(load_method)
        send(load_method, file_path)
      else
        raise RuntimeError, "config file type is not supported: #{type}"
      end
    end

    def load_yaml(file_path)
      require 'yaml'

      hash = YAML.load_file(file_path)
      self.load(hash)
    end
    alias :load_yml :load_yaml
  end
end
