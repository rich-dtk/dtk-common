module DTK; module Common
  class SequelAdapter
    class Postgres < self
      def initialize(db_params)
        super()
        ::Sequel.postgres(db_params[:name], :user => db_params[:user],  :host => db_params[:hostname], :password => db_params[:pass])
      end
    end
  end
end
