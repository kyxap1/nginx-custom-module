### nginx-custom-module
===================

* nginx 3rd party module builder script
* debian wheezy 7.5
* nginx-rtmp-module (as example)

Script will:

1. add backports repository
2. install nginx-extras sources
3. clone module from github
4. include module in nginx build
5. recompile nginx
6. create local repo from nginx .deb's and add it to apt cache
7. installs nginx-extras


