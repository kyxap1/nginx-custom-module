#!/usr/bin/env bash

set -e

# git repo with module sources
MODULE_GIT="https://github.com/arut/nginx-rtmp-module.git"
MODULE_NAME=`basename ${MODULE_GIT##*/} .git`

# tmp dir to compile nginx
WORKDIR="/opt/src/nginx_tmp"

# local apt repo dir
REPODIR="/opt/deb"

# fill sources
BACKPORTS_LIST=/etc/apt/sources.list.d/backports.list
[[ -f $BACKPORTS_LIST ]] || cat > $BACKPORTS_LIST <<EOF
deb http://ftp.debian.org/debian/ wheezy-backports main
deb-src http://ftp.debian.org/debian/ wheezy-backports main

EOF

# update apt cache
apt-get -q clean
apt-get -q update

# required packages
apt-get -qy install git devscripts

# install build dependencies for nginx
apt-get -qy build-dep -t wheezy-backports nginx-extras

# create workdir
mkdir -p $WORKDIR && cd $WORKDIR

# fetching nginx sources
apt-get -qy source -t wheezy-backports nginx

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

# installing nginx-extras package with custom module
apt-get -qy install nginx-extras

# archiving entire build env
[[ -d $WORKDIR ]] && tar --remove-files -czf $WORKDIR.`date +%F_%T`.tar.gz $WORKDIR

exit 0
