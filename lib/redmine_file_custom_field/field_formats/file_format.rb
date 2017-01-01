module RedmineFileCustomField
  module FieldFormat
    class FileFormat < Redmine::FieldFormat::Base
      include ActionView::Helpers::NumberHelper

      self.multiple_supported = true
      self.searchable_supported = true
      self.form_partial = 'custom_fields/formats/file'
      add 'file'

      def edit_tag(view, tag_id, tag_name, custom_field_value, options={})
        cf = custom_field_value.custom_field
        value = custom_field_value.value.try(:to_a) || []

        if cf.multiple?
          attachments = value
                          .map { |v| v.to_i > 0 ? Attachment.find(v) : nil }
                          .compact

          attachments.each do |attachment|
            if attachment and attachment.container_id \
              and attachment.container_id != custom_field_value.customized.custom_value_for(custom_field_value.custom_field).id
              attachment = attachment.dup
              attachment.container_id = nil
              attachment.save!
              custom_field_value.value = attachment.id
            end
          end
        else
          attachments = []
        end

        view.content_tag(:span) do
          attachments.each do |attachment|
            span_content = view.hidden_field_tag(tag_name, attachment.id) +
                           view.content_tag(:span, attachment.filename) +
                           view.link_to('&nbsp;'.html_safe, 'javascript:void(0)',
                                        onclick: "$(this).parent().remove();",
                                        class: 'remove-upload').html_safe

            view.concat view.content_tag(:span, span_content, style: 'display: block')
          end

          view.concat view.content_tag(:span,
            view.hidden_field_tag(tag_name, nil) +
            view.content_tag(:span, '') +
            view.link_to('&nbsp;'.html_safe, 'javascript:void(0)',
                         onclick: "$(this).parent().remove();",
                         style: 'display: none',
                         class: 'remove-upload').html_safe +
            view.file_field_tag("dummy_#{tag_name}", onchange: (dummy_input_onchange if cf.multiple?)))
        end
      end

      def formatted_custom_value(view, custom_value, html = false)
        value = custom_value.value

        return '' unless value.present?

        attachments = Attachment.where(id: value)

        if attachments.any?
          if html
            attachments.map { |a| view.link_to_attachment(a, thumbnails: true) }
              .join(', ').html_safe
          else
            attachments.map(&:filename).join(', ')
          end
        end
      end

      private

      # Javascript to be execute when file is uploaded.
      # Using hooks injecting this code would be overkill.
      def dummy_input_onchange
        <<END_JS.gsub(/\s+/, '')
        (function($i) {
          $(document).ajaxSuccess(function() {
            $i.parent().before(
              $i.parent().clone().find('input[type=file]').remove().end()
                .find('span').text($i[0].files[0].name).end()
                .find('a').show().end());
            $i.parent().find('input').val('');
          });
        })($(this));
END_JS
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
    end
  end
end
