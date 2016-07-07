module RedmineFileCustomField
  module FieldFormat
    class FileFormat < Redmine::FieldFormat::Base

      self.form_partial = 'custom_fields/formats/file'
      add 'file'

      def edit_tag(view, tag_id, tag_name, custom_field_value, options={})
        view.content_tag("span") do
          (view.hidden_field_tag(tag_name, custom_field_value.value, options.merge(:id => tag_id)) +
          view.file_field_tag(tag_name, options.merge(:id => tag_id)) +
          if (custom_value = CustomValue.find_by_customized_id_and_custom_field_id(custom_field_value.customized.id, custom_field_value.custom_field.id)) && (attachment = custom_value.attachments.find_by_id(custom_field_value.value))
            view.content_tag("span", id: "tag_id") do
              view.content_tag("span") do
                attachment.filename
              end +
              view.link_to('&nbsp;'.html_safe, "javascript:$('##{tag_id}').val('');$('#tag_id').hide();void(0);", class: 'remove-upload').html_safe
            end
          else
            ""
          end)

        end
      end

      def validate_single_value(custom_field, value, customized=nil)
        if value.is_a?(String)
          return [] unless a = Attachment.find_by_id(value)
        else
          a = value
        end

        if custom_field.possible_values.blank? || a.content_type.in?(custom_field.possible_values)
          []
        else
          [::I18n.t('activerecord.errors.messages.format_invalid')]
        end
      end

      def formatted_custom_value(view, custom_value, html=false)
        custom_value = CustomValue.find_by_customized_id_and_custom_field_id(custom_value.customized.id, custom_value.custom_field.id)

        if attachment = custom_value.attachments.find_by_id(custom_value.value)
          view.link_to_attachment attachment, thumbnails: true
        end
      end
    end
  end
end
