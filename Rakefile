require "bundler"
Bundler.setup

require 'rake/testtask'

desc 'Test the library.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

gemspec = eval(File.read("iptc.gemspec"))

desc "buidl the gem"
task :build => "#{gemspec.full_name}.gem"

file "#{gemspec.full_name}.gem" => gemspec.files + ["iptc.gemspec"] do
  system "gem build iptc.gemspec"
  system "gem install iptc-#{IPTC::VERSION}.gem"
end

desc 'Benchmark marker loading'
task :benchmark_loading do
	$: << 'lib'
	require 'iptc'
	IPTC::MarkerNomenclature.instance.benchmark
	
end
