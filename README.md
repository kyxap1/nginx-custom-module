## 3rd party modules installer for Nginx

Debian proposed method of own build packages handling is a little bit tricky and hard to remember process, especially if doing manually. The one of the most bothering things in the world, I guess. So, there is another yet quick and dirty bash script to automate build/installation/upgrade nginx with custom modules.

Script will:

* install nginx sources and build dependencies from wheezy-backports
* fetch module source code from git and properly integrate with nginx build configuration
* propagate dir-based local repository with nginx .deb packages and add this to the apt configuration
* backup build dir with tar/gzip to save last successful build
