module RedmineFileCustomField
  module Patches
    module CustomValuePatch
      def self.included(base) # :nodoc
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        # Same as typing in the class
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in developmen
          acts_as_attachable :after_add => :attachment_added, :after_remove => :attachment_removed


          def attachments_visible?(user=User.current)
            true
          end

          def attachments_editable?(user=User.current)
            false
          end

          def attachments_deletable?(user=User.current)
            true
          end
        end
      end

      module ClassMethods; end

      module InstanceMethods
        # TODO: Tried alias_method_chain :value=, :file but didn't work
        def value=(value)
          if custom_field.field_format == "file" && !value.blank? && value.is_a?(ActionDispatch::Http::UploadedFile)
            attachment = Attachment.new(:file => value.tempfile)
            attachment.author = User.current
            attachment.filename = value.original_filename
            attachment.content_type = value.content_type
            saved = attachment.save

            if saved
              saved_attachments << attachment
              value = attachment.id
            end
          elsif !value.blank?
            if !Attachment.find_by_id(value)
              value = nil
            end
          end

          write_attribute(:value, value)
        end

        def attachment_added(attachment)
        end

        def attachment_removed(attachment)
          if value.to_i == attachment.id
            self.value = nil
            self.save!
          end
        end
      end
    end
  end
end
