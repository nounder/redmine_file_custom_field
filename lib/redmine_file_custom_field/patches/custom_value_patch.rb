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
          if custom_field && custom_field.field_format == "file"
            if !value.blank?
              if value.is_a?(Attachment)
                saved_attachments << value
                value = value.id.to_s
              else
                if (attachment = Attachment.find_by_id(value))
                  (saved_attachments << attachment) if !attachment.container_id
                  value = attachment.id.to_s
                else
                  value = nil
                end
              end
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
