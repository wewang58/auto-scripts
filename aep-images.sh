#!/bin/bash
#This script is for aep images setup

RUBY20=(ruby-20-rhel7-aep 'https://github.com/openshift/sti-ruby.git --context-dir=2.0/test/puma-test-app/' openshift3/ruby-20-rhel7)
RUBY22=(ruby-22-rhel7-aep 'https://github.com/openshift/sti-ruby.git --context-dir=2.2/test/puma-test-app/' rhscl/ruby-22-rhel7)
NODEJS=(nodejs-010-rhel7-aep 'https://github.com/openshift/sti-nodejs.git --context-dir=0.10/test/test-app/' openshift3/nodejs-010-rhel7)
PERL516=(perl-516-rhel7-aep 'https://github.com/openshift/sti-perl.git --context-dir=5.16/test/sample-test-app/' openshift3/perl-516-rhel7)
PERL520=(perl-520-rhel7-aep 'https://github.com/openshift/sti-perl.git --context-dir=5.20/test/sample-test-app/' rhscl/perl-520-rhel7)
PYTHON27=(python-27-rhel7-aep 'https://github.com/openshift/sti-python.git --context-dir=2.7/test/setup-test-app/' rhscl/python-27-rhel7)
PYTHON33=(python-33-rhel7-aep 'https://github.com/openshift/sti-python.git --context-dir=3.3/test/setup-test-app/' openshift3/python-33-rhel7)
PYTHON34=(python-34-rhel7-aep 'https://github.com/openshift/sti-python.git --context-dir=3.4/test/setup-test-app/' rhscl/python-34-rhel7)
PHP55=(php-55-rhel7-aep 'https://github.com/openshift/sti-php.git --context-dir=5.5/test/test-app/' openshift3/php-55-rhel7)
PHP56=(php-56-rhel7-aep 'https://github.com/openshift/sti-php.git --context-dir=5.6/test/test-app/' rhscl/php-56-rhel7)
TOMCAT7=(webserver30-tomcat7-openshift-aep 'https://github.com/bparees/openshift-jee-sample' jboss-webserver-3/webserver30-tomcat7-openshift)
TOMCAT8=(webserver30-tomcat8-openshift-aep 'https://github.com/bparees/openshift-jee-sample' jboss-webserver-3/webserver30-tomcat8-openshift)
IMAGE=(RUBY20 RUBY22 NODEJS PERL516 PERL520 PYTHON27 PYTHON33 PYTHON34 PHP55 PHP56 TOMCAT7 TOMCAT8)

wget -O s2i.tar.gz https://github.com/openshift/source-to-image/releases/download/v1.0.4/source-to-image-v1.0.4-00785d6-linux-amd64.tar.gz
mkdir s2i
tar -zxvf s2i.tar.gz -C s2i
export PATH=$PATH:`pwd`/s2i
CMD=`which s2i`
DIR=`pwd`/s2i/s2i
if [ "$CMD" = "$DIR" ];then 
    echo "s2i tool install successfully"
else 
    echo "s2i tool install failed"
     exit
fi  

for (( i=0; i<${#IMAGE[@]} ; i++))   ; do
#source to image, push to registry, base registry
    SOURCE=$(eval echo \${${IMAGE[$i]}[1]})
    REG=$(eval echo \${${IMAGE[$i]}[2]})
    NAME=$(eval echo \${${IMAGE[$i]}[0]})
    s2i build $SOURCE  registry.access.redhat.com/$REG  $NAME
    docker tag -f $NAME virt-openshift-05.lab.eng.nay.redhat.com:5001/aep-release/$NAME
    docker push virt-openshift-05.lab.eng.nay.redhat.com:5001/aep-release/$NAME |tee -a push.log
#check push successful
    DIFF=`cat push.log |grep sha256 |cut -d ':' -f1,2,3`
    if [ "$DIFF" != "latest: digest: sha256" ];then 
       echo "push release $NAME failed"
    else 
       echo "push release $NAME successfully"
    fi
    rm -f push.log
#source to image, push to registry, base rcm
    s2i build $SOURCE  rcm-img-docker01.build.eng.bos.redhat.com:5001/$REG  $NAME
    docker tag -f $NAME virt-openshift-05.lab.eng.nay.redhat.com:5001/aep-upgrade/$NAME
    docker push virt-openshift-05.lab.eng.nay.redhat.com:5001/aep-upgrade/$NAME |tee -a push.log
#check push successful
    DIFF=`cat push.log |grep sha256 |cut -d ':' -f1,2,3`
    if [ "$DIFF" != "latest: digest: sha256" ];then
       echo "push upgrade $NAME failed"
    else
       echo "push upgrade $NAME successfully"
    fi
    rm -f push.log
done
