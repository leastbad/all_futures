module AllFutures::Attributes
  extend ActiveSupport::Concern

  class_methods do
    def has_future(name, klass, **options)
      ivar_symbol = :"@#{name}_all_futures"

      define_method(name) do
        if instance_variable_defined?(ivar_symbol)
          instance_variable_get(ivar_symbol)
        else
          af_key = if options[:key]
            options[:key]
          else
            record_id = try(:id) or raise ActiveRecord::RecordNotSaved, "AllFutures requires a unique key. Either save this record before accessing #{name}, or pass a custom key."
            "#{self.class.name.tableize.tr("/", ":")}:#{record_id}:#{name}"
          end
          af = klass.exists?(af_key) ? klass.find(af_key) : klass.create(id: af_key)
          instance_variable_set(ivar_symbol, af)
        end
      end
    end
  end
end
