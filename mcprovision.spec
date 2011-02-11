%define ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%define release %{rpm_release}%{?dist}

Summary: Server Provisioner for Puppet and MCollective
Name: mcprovision
Version: %{version}
Release: %{release}
Group: System Tools
License: Apache v2
URL: http://www.devco.net/
Source0: %{name}-%{version}.tgz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: ruby
Requires: mcollective-client
Packager: R.I.Pienaar <rip@devco.net>
BuildArch: noarch

%description
Automated the provisioning of servers in a Puppet environment via MCollective

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
%{__install} -d -m0755  %{buildroot}/%{ruby_sitelib}/mcprovision
%{__install} -d -m0755  %{buildroot}/etc/mcollective
%{__install} -d -m0755  %{buildroot}/usr/sbin
%{__install} -d -m0755  %{buildroot}/etc/init.d
%{__install} -d -m0755  %{buildroot}/etc/sysconfig
%{__install} -m0755 mcprovision.rb %{buildroot}/usr/sbin/mcprovision
%{__install} -m0755 mcprovision.init %{buildroot}/etc/init.d/mcprovision
%{__install} -m0644 etc/provisioner.yaml.dist %{buildroot}/etc/mcollective/mcprovision.yaml
%{__install} -m0600 etc/mcprovision.defaults %{buildroot}/etc/sysconfig/mcprovision
cp -R lib/* %{buildroot}/%{ruby_sitelib}/

%clean
rm -rf %{buildroot}

%post
/sbin/chkconfig --add mcprovision

%preun
if [ "$1" = 0 ]; then
   /sbin/service mcprovision stop >/dev/null 2>&1 || :;
   /sbin/chkconfig --del mcprovision || :;
fi
:;

%postun
if [ "$1" -ge 1 ]; then
   /sbin/service mcprovision condrestart >/dev/null 2>&1 || :;
fi;
:;

%files
%{ruby_sitelib}/mcprovision.rb
%{ruby_sitelib}/mcprovision
%config(noreplace) /etc/mcollective/mcprovision.yaml
%config(noreplace) /etc/sysconfig/mcprovision
/etc/init.d/mcprovision
/usr/sbin/mcprovision


%changelog
* Thu Feb 11 2011 R.I.Pienaar <rip@devco.net> - 1.0.0
- First release
