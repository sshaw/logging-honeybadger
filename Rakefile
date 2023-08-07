require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

# I think Minitest::TestTask does this but only certain versions? Was seeing some CI failures without it
task :default => :test
