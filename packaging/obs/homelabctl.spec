#----------------------------------------------------------------------------------------------------------------------#
# Notes
# 1) Release vs Version
# - Version: Source version, typically matches Git tag/release (e.g., v0.1.0 -> 0.1.0)
# - Release: Iteration number for the same Version (usually for spec file changes)
# 2) Changelog format
# - First line: * Day Mon DD YYYY Name <email> - Version-Release
# - Following lines: - change description
#----------------------------------------------------------------------------------------------------------------------#

Name:           homelabctl
Version:        0.2.5
Release:        1%{?dist}
Summary:        CLI tool for managing homelab infrastructure

License:        MIT
URL:            https://github.com/xooooooooox/homelabctl
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

BuildArch:      noarch
Requires:       bash
Requires:       coreutils
Requires:       radp-bash-framework

%description
homelabctl is a CLI tool for managing homelab infrastructure, built on top of
radp-bash-framework. It provides a unified interface for orchestrating various
homelab components including Vagrant-based virtual machines.

%prep
%setup -q -n homelabctl-%{version}

%build
# nothing to build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_libdir}/homelabctl
cp -a bin %{buildroot}%{_libdir}/homelabctl/
cp -a src %{buildroot}%{_libdir}/homelabctl/

# Remove IDE support files (development only, not needed at runtime)
find %{buildroot}%{_libdir}/homelabctl/src -name "_ide*.sh" -delete

chmod 0755 %{buildroot}%{_libdir}/homelabctl/bin/homelabctl
find %{buildroot}%{_libdir}/homelabctl/src -type f -name "*.sh" -exec chmod 0755 {} \;
mkdir -p %{buildroot}%{_bindir}
ln -s %{_libdir}/homelabctl/bin/homelabctl %{buildroot}%{_bindir}/homelabctl

# install shell completions
mkdir -p %{buildroot}%{_datadir}/bash-completion/completions
mkdir -p %{buildroot}%{_datadir}/zsh/site-functions
cp -a completions/homelabctl.bash %{buildroot}%{_datadir}/bash-completion/completions/homelabctl
cp -a completions/homelabctl.zsh %{buildroot}%{_datadir}/zsh/site-functions/_homelabctl

%files
%license LICENSE
%doc README.md
%{_bindir}/homelabctl
%{_libdir}/homelabctl/
%{_datadir}/bash-completion/completions/homelabctl
%{_datadir}/zsh/site-functions/_homelabctl

%changelog
* Sat Jan 25 2026 xooooooooox <xozoz.sos@gmail.com> - 0.1.0-1
- Initial RPM package
