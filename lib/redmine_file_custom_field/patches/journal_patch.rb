module RedmineFileCustomField
  module Patches
    module JournalPatch
      def self.included(base) # :nodoc
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        # Same as typing in the class
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in developmen

          alias_method_chain :add_custom_value_detail, :file
        end
      end

      module ClassMethods; end

      module InstanceMethods
        def add_custom_value_detail_with_file(custom_value, old_value, value)
          if custom_value.custom_field.field_format == "file"
            add_custom_value_detail_without_file(custom_value, file_value(old_value), file_value(value))
          else
            add_custom_value_detail_without_file(custom_value, old_value, value)
          end
        end

        def file_value(value)
          if value.is_a?(ActionDispatch::Http::UploadedFile)
            value.original_filename
          else
            Attachment.find_by_id(value).try(:filename)
          end
        end
      end
    end
  end
end
