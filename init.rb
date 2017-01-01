Redmine::Plugin.register :redmine_file_custom_field do
  name "Redmine File Custom Field plugin"
  author "Ralph Gutkowski"
  description "Provides File format for Custom Fields."
  version '0.2.0'
  url 'https://github.com/rgtk/redmine_file_custom_field'
  author_url 'https://github.com/rgtk'

  settings default: {}, :partial => 'settings/redmine_file_custom_field'
end

require 'redmine_file_custom_field/field_formats/file_format'
require 'redmine_file_custom_field/content_types'
require 'redmine_file_custom_field/hooks/issue_hook'

Ddr::Antiviruss.canner_adapter = :clamd if defined?(Ddr)

ActionDispatch::Reloader.to_prepare do
  CustomValue.send(:include, RedmineFileCustomField::Patches::CustomValuePatch) unless CustomValue.included_modules.include?(RedmineFileCustomField::Patches::CustomValuePatch)
  Journal.send(:include, RedmineFileCustomField::Patches::JournalPatch) unless Journal.included_modules.include?(RedmineFileCustomField::Patches::JournalPatch)
  Redmine::Acts::Customizable::InstanceMethods.send(:include, RedmineFileCustomField::Patches::CustomizablePatch) unless Redmine::Acts::Customizable::InstanceMethods.included_modules.include?(RedmineFileCustomField::Patches::CustomizablePatch)
end
