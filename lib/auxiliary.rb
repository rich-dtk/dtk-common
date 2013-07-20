#TODO: will start moving over to using DtkCommon namespace; versions in DtkCommon namespace also in DTK::Common are teh upgraded versions
require 'etc'

module DtkCommon
  module Aux
    def self.dtk_instance_repo_username(tenant_id=nil)
      instance_unique_id = get_ec2_instance_id() || get_macaddress().gsub(/:/,'-')
      tenant_id ||= ::DTK::Common::Aux.running_process_user()
      "dtk-#{instance_unique_id}--#{tenant_id}"
    end
  end
end

module DTK
  module Common
    module AuxMixin
      def get_ssh_rsa_pub_key()
        path = "#{running_process_home_dir()}/.ssh/id_rsa.pub"
        begin
          File.open(path){|f|f.read}.chomp
         rescue Errno::ENOENT
          raise Error.new("user (#{ENV['USER']}) does not have a public key under #{path}")
         rescue => e
          raise e
         end
      end

      def hash_subset(hash,keys_subset,opts={})
        keys_subset.inject(Hash.new) do |h,k|
          index = k.kind_of?(Hash) ? k.keys.first : k
          if opts[:no_non_nil] and hash[index].nil? then h
          elsif not hash.has_key?(index) then h
          else
            key = k.kind_of?(Hash) ? k.values.first : k
            val = hash[index]
            h.merge(key => val)
          end
        end
      end

      def convert_keys_to_symbols(hash)
        hash.keys.inject(Hash.new){|h,k|h.merge(k.to_sym => hash[k])}
      end

      def dtk_instance_repo_username()
        #on ec2 changing mac addresses; so selectively pick instance id on ec2
        unique_id = get_ec2_instance_id() || get_macaddress().gsub(/:/,'-')
        "dtk-#{unique_id}"
      end

      def update_ssh_known_hosts(remote_host)
        fingerprint = `ssh-keyscan -H -t rsa #{remote_host}`
        ssh_known_hosts = "#{running_process_home_dir()}/.ssh/known_hosts"
        if File.file?(ssh_known_hosts)
          `ssh-keygen -f "#{ssh_known_hosts}" -R #{remote_host}`
        end
        File.open(ssh_known_hosts,"a"){|f| f << "#{fingerprint}\n"}
      end

      def get_macaddress()
        return @macaddress if @macaddress
        #TODO: may just use underlying routines for facter - macaddress
        require 'facter'
        collection = ::Facter.collection
        @macaddress = collection.fact('macaddress').value
      end

      def get_ec2_public_dns()
        get_ec2_meta_data('public-hostname')
      end

      def get_ec2_instance_id()
        # @ec2_instance_id_cached used because it could have tried to get this info and result was null
        return @ec2_instance_id if @ec2_instance_id_cached
        @ec2_instance_id_cached = true
        @ec2_instance_id = get_ec2_meta_data('instance-id')
      end

      def snake_to_camel_case(snake_case)
        snake_case.gsub(/(^|_)(.)/) { $2.upcase }
      end

      def platform_is_linux?()
        RUBY_PLATFORM.downcase.include?("linux")
      end

      def platform_is_windows?()
        RUBY_PLATFORM.downcase.include?("mswin") or RUBY_PLATFORM.downcase.include?("mingw")
      end

      def  running_process_user()
        if platform_is_windows?()
          Etc.getlogin
        else
          Etc.getpwuid(Process.uid).name
        end
      end

      def running_process_home_dir()
        if platform_is_windows?()
          File.expand_path('~')
        else
          Etc.getpwuid(Process.uid).dir
        end
      end

     private
      def get_ec2_meta_data(var)
       #Fragments taken from Puppetlabs facter ec2
        require 'open-uri'
        require 'timeout'
        ret = nil
        begin 
          url = "http://169.254.169.254:80/"
          Timeout::timeout(WaitSec) {open(url)}
          ret = OpenURI.open_uri("http://169.254.169.254/2008-02-01/meta-data/#{var}").read
         rescue Timeout::Error
         rescue
          #TODO: unexpected; write t log what error is
        end
        ret
      end    
      WaitSec = 2
    end
    module Aux
      class << self
        include AuxMixin
      end
    end
  end
end
