#!/usr/bin/env bash

# tmp dir to compile nginx
WORKDIR=/opt/src/tmp.build-nginx
# local apt repo dir
REPODIR=/opt/deb

# fill sources
BACKPORTS_LIST=/etc/apt/sources.list.d/backports.list
[[ -f $BACKPORTS_LIST ]] || cat > $BACKPORTS_LIST <<EOF
deb http://ftp.debian.org/debian/ wheezy-backports main
deb-src http://ftp.debian.org/debian/ wheezy-backports main

EOF

# update apt cache
apt-get -q update

# required packages
apt-get -qy install git devscripts

# install build dependencies for nginx
apt-get -qy build-dep -t wheezy-backports nginx-extras

# gzip prev work dir
[[ -d $WORKDIR ]] && tar --remove-files -czf $WORKDIR.`date +%F_%T`.tar.gz /opt/src/tmp.build-nginx

# create workdir
mkdir -p $WORKDIR

# change dir to workdir
cd $WORKDIR

# get nginx sources
apt-get -qy source -t wheezy-backports nginx-extras

# download nginx-rtmp-module sources
git clone https://github.com/arut/nginx-rtmp-module.git

# add module to debian/rules file
sed "s#\(^\s\+\)--with-http_ssl_module.\+#&\n\1--add-module=$WORKDIR/nginx-rtmp-module \\\#g" -i $WORKDIR/nginx-*/debian/rules

# update 1st line of changelog
sed -e '1s/(\(.\+\))/(\1.rtmp)/' -i $WORKDIR/nginx-*/debian/changelog

# build nginx with rtmp module
cd $WORKDIR/nginx-*
debuild -i -us -uc -b -j`grep ^processor /proc/cpuinfo | wc -l`

# create local nginx repo dir
[[ -d $REPODIR/nginx ]] || mkdir -p $REPODIR/nginx

# move new .deb's to local
mv $WORKDIR/*.deb $REPODIR/nginx/

# generate Packages.gz for local nginx repo
dpkg-scanpackages nginx /dev/null | gzip -c > /opt/deb/nginx/Packages.gz

# add local nginx repo to apt
REPO_LIST=/etc/apt/sources.list.d/nginx-local.list
[[ -f $REPO_LIST ]] || cat > $REPO_LIST <<EOF
deb [trusted=yes] file://$REPODIR nginx/

EOF

# update apt cache
apt-get -qy update

# install nginx-extras package with rtmp module
apt-get -qy install nginx-extras



