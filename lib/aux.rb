#TODO: move app aux to heer and then just rename to Aux
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

      def dtk_instance_repo_username()
        #on ec2 changing mac addresses; so selectively pick instance id on ec2
        unique_id = Common::Aux.get_ec2_instance_id() || Common::Aux.get_macaddress().gsub(/:/,'-')
        "dtk-#{unique_id}"
      end

      def get_macaddress()
        return @macaddress if @macaddress
        require 'facter'
        collection = ::Facter.collection
        @macaddress = collection.fact('macaddress').value
      end

      def get_ec2_instance_id()
        return @ec2_instance_id if @ec2_instance_id
        require 'facter'
        collection = ::Facter.collection
        @ec2_instance_id = collection.fact('ec2_instance_id').value
      end

      private
      def running_process_home_dir()
        File.expand_path("~#{ENV['USER']}") 
      end
    
    end
    module Aux
      class << self
        include AuxMixin
      end
    end
  end
end
