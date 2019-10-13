module Cenit
  module MultiTenancy
    module Scoped
      extend ActiveSupport::Concern

      included do
        store_in collection: -> { Cenit::MultiTenancy.tenant_model.tenant_collection_name(collectionizable_name) }
      end

      module ClassMethods

        def collectionizable_name
          to_s
        end

        def mongoid_root_class
          @mongoid_root_class ||=
            begin
              root = self
              root = root.superclass while root.superclass.include?(Mongoid::Document)
              root
            end
        end

        def with_current_tenant
          with(Cenit::MultiTenancy.tenant_model.current_tenant)
        end

        def with(options)
          tenant_option = false
          tenant = nil
          if options.is_a?(Cenit::MultiTenancy.tenant_model)
            tenant_option = tenant = options
            options = {}
          elsif options.is_a?(Hash)
            [
              :tenant,
              Cenit::MultiTenancy.tenant_model_key
            ].each do |key|
              next if tenant_option
              (tenant_option = options.has_key?(key)) && (tenant = options.delete(key))
            end
          end
          if block_given?
            unless tenant.is_a?(Cenit::MultiTenancy.tenant_model)
              tenant = Cenit::MultiTenancy.tenant_model.where(id: tenant).first
            end
            current = Cenit::MultiTenancy.tenant_model.current
            Cenit::MultiTenancy.tenant_model.current = tenant
            begin
              yield(self)
            ensure
              Cenit::MultiTenancy.tenant_model.current = current
            end
          else
            options = options.merge(collection: Cenit::MultiTenancy.tenant_model.tenant_collection_name(mongoid_root_class, tenant: tenant)) if tenant_option
	    # TODO need pass a block, to avoid error, the implmentation of with method changed 
	    # https://github.com/mongodb/mongoid/commit/25a375d47054304cf3d7537c7d3f21c591b8fb73
            super(options) {}
          end
        end
      end
    end
  end
end
