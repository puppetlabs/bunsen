require 'fileutils'

task :default do
  system("rake -T")
end

def version
  version = `git describe --tags  --abbrev=0`.chomp.sub('v','')
  version.empty? ? '0.0.0' : version
end

def next_version(type = :patch)
  section = [:major,:minor,:patch].index type

  n = version.split '.'
  n[section] = n[section].to_i + 1
  n.join '.'
end

desc "Build and publish image"
task :docker => [ 'docker:build', 'docker:push' ] do
  puts 'Published'
end

desc "Build Docker image"
task 'docker:build' do
  system("docker build --no-cache=true -t puppetlabs/bunsen:#{version} -t puppetlabs/bunsen:latest .")
  puts 'Start container manually with: docker run -it puppetlabs/bunsen'
  puts 'Or rake docker::run'
end

desc "Run Bunsen image locally for debugging"
task 'docker::run' do
  `docker run -it puppetlabs/bunsen`
end

desc "Upload image to GCE"
task 'docker:push' do
  system("docker tag puppetlabs/bunsen gcr.io/puppetlabs.com/api-project-531226060619/bunsen")
  system("docker push gcr.io/puppetlabs.com/api-project-531226060619/bunsen:#{version}")
  system("docker push gcr.io/puppetlabs.com/api-project-531226060619/bunsen:latest")
end
