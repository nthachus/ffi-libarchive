# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options << '--display-cop-names'
  t.fail_on_error = false
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  # Ensure SimpleCov is loaded before the test files
  t.ruby_opts << '-r "./test/test_helper"'
end

task default: [:rubocop, :test]
