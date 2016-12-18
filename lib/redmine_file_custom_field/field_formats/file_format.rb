module RedmineFileCustomField
  module FieldFormat
    class FileFormat < Redmine::FieldFormat::Base
      include ActionView::Helpers::NumberHelper

      self.multiple_supported = true
      self.searchable_supported = true
      self.form_partial = 'custom_fields/formats/file'
      add 'file'

      def edit_tag(view, tag_id, tag_name, custom_field_value, options={})
        cv_value = custom_field_value.value

        # TODO: Support single values
        if cv_value.is_a?(Array)
          attachments = cv_value
                          .map { |v| v.to_i > 0 ? Attachment.find(v) : nil }
                          .compcat
        else
          attachments = []
        end

        # if attachment and attachment.container_id \
        #   and attachment.container_id != custom_field_value.customized.custom_value_for(custom_field_value.custom_field).id
        #   attachment = attachment.dup
        #   attachment.container_id = nil
        #   attachment.save!
        #   custom_field_value.value = attachment.id
        #   value = custom_field_value.value
        # end

        view.content_tag(:span) do
          view.content_tag(:span) do
            attachments.each do |attachment|
              concat content_tag(:span, attachment.filename, class: 'filename')
            end
          end

          view.content_tag(:span, class: 'add_attachment') do
            view.file_field_tag tag_name,
                                class: 'file_selector',
                                multiple: true,
                                data: {
                                  max_file_size: Setting.attachment_max_size.to_i.kilobytes,
                                  max_file_size_message: l(:error_attachment_too_big, :max_size => number_to_human_size(Setting.attachment_max_size.to_i.kilobytes)),
                                  max_concurrent_uploads: Redmine::Configuration['max_concurrent_ajax_uploads'].to_i,
                                  upload_path: view.uploads_path(:format => 'js'),
                                  description_placeholder: l(:label_optional_description)
                                }
          end
        end
      end

      def validate_single_value(custom_field, value, customized=nil)
        byebug
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
