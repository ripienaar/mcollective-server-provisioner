# Rakefile to build a project using HUDSON

require 'rake/packagetask'
require 'rake/clean'
require 'find'

PROJ_DOC_TITLE = "MCollective Server Provisioner"
PROJ_VERSION = "1.0.0"
PROJ_RELEASE = "1"
PROJ_NAME = "mcprovision"
PROJ_RPM_NAMES = [PROJ_NAME]
PROJ_FILES = ["#{PROJ_NAME}.spec", "#{PROJ_NAME}.rb", "#{PROJ_NAME}.init", "COPYING", "lib", "etc", "agent", "data"]

ENV["RPM_VERSION"] ? CURRENT_VERSION = ENV["RPM_VERSION"] : CURRENT_VERSION = PROJ_VERSION
ENV["BUILD_NUMBER"] ? CURRENT_RELEASE = ENV["BUILD_NUMBER"] : CURRENT_RELEASE = PROJ_RELEASE

CLEAN.include("build")

def announce(msg='')
    STDERR.puts "================"
    STDERR.puts msg
    STDERR.puts "================"
end

def init
    FileUtils.mkdir("build") unless File.exist?("build")
end

desc "Build tar balls and rpms"
task :default => [:clean, :package, :rpm]

desc "Create a tarball for this release"
task :package => [:clean] do
    announce "Creating #{PROJ_NAME}-#{CURRENT_VERSION}.tgz"

    FileUtils.mkdir_p("build/#{PROJ_NAME}-#{CURRENT_VERSION}")
    system("cp -R #{PROJ_FILES.join(' ')} build/#{PROJ_NAME}-#{CURRENT_VERSION}")
    system("cd build && tar --exclude .svn --exclude .git -cvzf #{PROJ_NAME}-#{CURRENT_VERSION}.tgz #{PROJ_NAME}-#{CURRENT_VERSION}")
end

desc "Creates a RPM"
task :rpm => [:clean, :package] do
    announce("Building RPM for #{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}")

    sourcedir = `rpm --eval '%_sourcedir'`.chomp
    specsdir = `rpm --eval '%_specdir'`.chomp
    srpmsdir = `rpm --eval '%_srcrpmdir'`.chomp
    rpmdir = `rpm --eval '%_rpmdir'`.chomp
    lsbdistrel = `lsb_release -r -s | cut -d . -f1`.chomp
    lsbdistro = `lsb_release -i -s`.chomp

    case lsbdistro
        when 'CentOS'
            rpmdist = ".el#{lsbdistrel}"
        when 'AmazonAMI'
            rpmdist = '.amzn1'
        else
            rpmdist = ''
    end

    system %{cp build/#{PROJ_NAME}-#{CURRENT_VERSION}.tgz #{sourcedir}}
    system %{cat #{PROJ_NAME}.spec|sed -e s/%{rpm_release}/#{CURRENT_RELEASE}/g | sed -e s/%{version}/#{CURRENT_VERSION}/g > #{specsdir}/#{PROJ_NAME}.spec}
    system %{cd #{specsdir} && rpmbuild -D 'version #{CURRENT_VERSION}' -D 'rpm_release #{CURRENT_RELEASE}' -D 'dist #{rpmdist}' -ba #{PROJ_NAME}.spec}

    system %{cp #{srpmsdir}/#{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}#{rpmdist}.src.rpm build/}

    system %{cp #{rpmdir}/*/#{PROJ_NAME}*-#{CURRENT_VERSION}-#{CURRENT_RELEASE}#{rpmdist}.*.rpm build/}
end

# vi:tabstop=4:expandtab:ai
