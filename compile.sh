#!/usr/bin/env bash
# Usage:
#       ./compile.sh <GITREPO> [ DISTRO ] [ CODENAME ]
#
#  e.g. ./compile.sh https://github.com/arut/nginx-rtmp-module
#       ./compile.sh https://github.com/arut/nginx-rtmp-module.git
#       ./compile.sh https://github.com/arut/nginx-rtmp-module.git ubuntu trusty

set -e

MODULE_GIT=${1:?`echo 'No git url is set'; exit 1;`}
DISTRO=${2:-debian}
CODENAME=${3:-wheezy}

# git repo with module sources
MODULE_NAME=`basename ${MODULE_GIT##*/} .git`

# tmp dir to compile nginx
WORKDIR="/opt/src"

# local apt repo dir
REPODIR="/opt/deb"

# trust nginx key
wget http://nginx.org/keys/nginx_signing.key -q -O - | apt-key add -

# fill sources
NGINX_SOURCESLIST=/etc/apt/sources.list.d/nginx.list
[[ -f $NGINX_SOURCESLIST ]] || cat > $NGINX_SOURCESLIST <<EOF
# nginx official repository
deb http://nginx.org/packages/$DISTRO/ $CODENAME nginx
deb-src http://nginx.org/packages/$DISTRO/ $CODENAME nginx

EOF

# update apt cache
apt-get -q clean
apt-get -q update

# required packages
apt-get -qy install git devscripts

# install build dependencies for nginx
apt-get -qy build-dep nginx

# create workdir
mkdir -p $WORKDIR && cd $WORKDIR

# fetching nginx sources
apt-get -qy source nginx

# fetching nginx module sources
git clone $MODULE_GIT

# adding module to debian/rules file
sed "s#\(^\s\+\)--with-http_ssl_module.\+#&\n\1--add-module=$WORKDIR/$MODULE_NAME \\\#g" -i $WORKDIR/nginx-*/debian/rules

# updating 1st line of changelog
sed -e '1s/(\(.\+\))/(\1.custom)/' -i $WORKDIR/nginx-*/debian/changelog

# building nginx with custom module
cd $WORKDIR/nginx-*
debuild -i -us -uc -b -j`grep ^processor /proc/cpuinfo | wc -l`

# creating local nginx repo dir
[[ -d $REPODIR/nginx ]] || mkdir -p $REPODIR/nginx

# moving new .deb's to local nginx repo
mv $WORKDIR/*.deb $REPODIR/nginx/

# generating Packages.gz for local nginx repo
cd $REPODIR
dpkg-scanpackages nginx /dev/null | gzip -c > $REPODIR/nginx/Packages.gz

# adding local nginx repo to apt
REPO_LIST=/etc/apt/sources.list.d/nginx-local.list
[[ -f $REPO_LIST ]] || cat > $REPO_LIST <<EOF
deb [trusted=yes] file://$REPODIR nginx/

EOF

# updating apt cache
apt-get -qy update

# installing nginx package with custom module
apt-get -qy install nginx

# uncomment to archive+delete build dir
# [[ -d $WORKDIR ]] && tar --remove-files -czf $WORKDIR.`+%F_%H-%M-%S`.tar.gz $WORKDIR

exit 0
