require 'sequel'
class DTK::Common::DB::Adapter
  class Postgres < self
    def initialize(db_params)
      super()
      ::Sequel.postgres(db_params[:name], :user => db_params[:user],  :host => db_params[:hostname], :password => db_params[:pass])
    end
  end
end

