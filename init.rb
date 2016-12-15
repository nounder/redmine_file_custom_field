Redmine::Plugin.register :redmine_file_custom_field do
  name 'Redmine File Custom Field plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  require 'redmine_file_custom_field/field_formats/file_format'
  require 'redmine_file_custom_field/content_types'
  require 'redmine_file_custom_field/hooks/issue_hook'

  settings default: {}, :partial => 'settings/redmine_file_custom_field'

  CustomValue.send(:include, RedmineFileCustomField::Patches::CustomValuePatch) unless CustomValue.included_modules.include?(RedmineFileCustomField::Patches::CustomValuePatch)
  Journal.send(:include, RedmineFileCustomField::Patches::JournalPatch) unless Journal.included_modules.include?(RedmineFileCustomField::Patches::JournalPatch)
  Redmine::Acts::Customizable::InstanceMethods.send(:include, RedmineFileCustomField::Patches::CustomizablePatch) unless Redmine::Acts::Customizable::InstanceMethods.included_modules.include?(RedmineFileCustomField::Patches::CustomizablePatch)

  if defined?(Ddr)
    Ddr::Antiviruss.canner_adapter = :clamd
  end
end
