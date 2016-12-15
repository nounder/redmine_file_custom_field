module RedmineFileCustomField
  module FieldFormat
    class FileFormat < Redmine::FieldFormat::Base
      include ActionView::Helpers::NumberHelper

      self.form_partial = 'custom_fields/formats/file'
      add 'file'

      def edit_tag(view, tag_id, tag_name, custom_field_value, options={})
        if custom_field_value.value.is_a?(Attachment)
          value = custom_field_value.value.id
          attachment = custom_field_value.value
        else
          value = custom_field_value.value
          attachment = custom_field_value.value.blank? ? nil : Attachment.find(value)
        end

        if attachment && attachment.container_id && attachment.container_id != custom_field_value.customized.custom_value_for(custom_field_value.custom_field).id
          attachment = attachment.dup
          attachment.container_id = nil
          attachment.save!
          custom_field_value.value = attachment.id
          value = custom_field_value.value
        end

        view.content_tag("span") do
          (view.hidden_field_tag(tag_name, value, options.merge(:id => tag_id)) +
          view.file_field_tag("tmp_#{tag_name}", options.merge(:id => tag_id)) +
          if (attachment)
            view.content_tag("span", id: "tag_id", style: 'display: block;') do
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
          return [] unless attachment = Attachment.find_by_id(value)
        else
          attachment = value
        end
        err = []

        err = err | validate_content_type(custom_field, attachment)
        err = err | validate_size(custom_field, attachment)

        if Setting.plugin_redmine_file_custom_field['scan_for_virus']
          err = err | validate_virus(custom_field, attachment)
        end

        err
      end

      def validate_content_type(custom_field, attachment)
        if custom_field.possible_values.blank? || custom_field.possible_values.detect { |e| attachment.disk_filename.downcase.ends_with?(".#{e.downcase}") }
          []
        else
          [::I18n.t('activerecord.errors.messages.format_invalid')]
        end
      end

      def validate_size(custom_field, attachment)
        max_size = Setting.attachment_max_size.to_i.kilobytes

        if attachment.filesize < max_size
          []
        else
          [::I18n.t(:error_attachment_too_big, max_size: number_to_human_size(max_size))]
        end
      end

      def validate_virus(custom_field, attachment)
        if defined?(Ddr)
          begin
            Ddr::Antivirus.scan(attachment.diskfile)
            []
          rescue Ddr::Antivirus::VirusFoundError
            [::I18n.t('activerecord.errors.messages.virus_founded')]
          rescue
            [::I18n.t('activerecord.errors.messages.clamd_not_working')]
          end
        else
          []
        end
      end

      def formatted_custom_value(view, custom_value, html=false)
        custom_value = CustomValue.find_by_customized_id_and_custom_field_id(custom_value.customized.id, custom_value.custom_field.id)

        if custom_value && attachment = Attachment.find_by_id(custom_value.value)
          if attachment.container_id && attachment.container_id != custom_value.id
            attachment = attachment.dup
            attachment.container_id = custom_value.id
            attachment.save!

            custom_value.value = attachment.id
            custom_value.save!
          end

          if html
            view.link_to_attachment attachment, thumbnails: true
          else
            attachment.filename
          end
        end
      end
    end
  end
end
