module RedmineFileCustomField
  module Hooks
    class IssueHook < Redmine::Hook::ViewListener
      render_on :view_issues_form_details_bottom, partial: 'redmine_file_custom_field/issue_form_hook.html'
    end
  end
end
