module RedmineFileCustomField
  module Patches
    module CustomizablePatch
      def self.included(base) # :nodoc
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in developmen
          alias_method_chain :custom_field_values=, :file

        end
      end

      module ClassMethods
      end

      module InstanceMethods

        # TODO: Verificar como chamar o without,
        # tentei fazer separando o values de arquivo dos outros e jogando para o widhout,
        # e fazendo a lógica de atribuição nova somente para o file
        # mas ao chamar o widhout ele não chamava a versão acts_as_customizable
        def custom_field_values_with_file=(values)
          values = values.stringify_keys
          custom_field_values.each do |custom_field_value|
            key = custom_field_value.custom_field_id.to_s
            if values.has_key?(key)
              value = values[key]
              if value.is_a?(Array)
                value = value.reject(&:blank?).map(&:to_s).uniq
                if value.empty?
                  value << ''
                end
              elsif !value.is_a?(ActionDispatch::Http::UploadedFile)
                value = value.to_s
              end
              custom_field_value.value = value
            end
          end
          @custom_field_values_changed = true
        end
      end
    end
  end
end
