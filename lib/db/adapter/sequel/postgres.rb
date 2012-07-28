require 'sequel'
class DTK::Common::DB::Adapter
  class Postgres < self
    def self.create(db_params)
      ::Sequel.postgres(db_params[:name], :user => db_params[:user],  :host => db_params[:hostname], :password => db_params[:pass])
    end
  end
end

