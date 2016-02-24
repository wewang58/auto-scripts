#!/bin/bash
#This script is for pulling and pushing test images

RUBY20=$'openshift3/ruby-20-rhel7'
RUBY22=$'rhscl/ruby-22-rhel7'
NODEJS=$'openshift3/nodejs-010-rhel7'
PERL516=$'openshift3/perl-516-rhel7'
PERL520=$'rhscl/perl-520-rhel7'
PYTHON27=$'rhscl/python-27-rhel7'
PYTHON33=$'openshift3/python-33-rhel7'
PYTHON34=$'rhscl/python-34-rhel7'
PHP55=$'openshift3/php-55-rhel7'
PHP56=$'rhscl/php-56-rhel7'
TOMCAT7=$'jboss-webserver-3/webserver30-tomcat7-openshift'
TOMCAT8=$'jboss-webserver-3/webserver30-tomcat8-openshift'
EAP64=$'jboss-eap-6/eap64-openshift'
AMQ62=$'jboss-amq-6/amq62-openshift'
JENKINS=$'openshift3/jenkins-1-rhel7'
MYSQL55=$'openshift3/mysql-55-rhel7'
MYSQL56=$'rhscl/mysql-56-rhel7'
MONGO24=$'openshift3/mongodb-24-rhel7'
MONGO26=$'rhscl/mongodb-26-rhel7'
POST92=$'penshift3/postgresql-92-rhel7'
POST94=$'rhscl/postgresql94-rhel7'

IMAGE=(RUBY20 RUBY22 NODEJS PERL516 PERL520 PYTHON27 PYTHON33 PYTHON34 PHP55 PHP56 TOMCAT7 TOMCAT8 EAP64 AMQ62 JENKINS MYSQL55 MYSQL56 MONGO24 MONGO26 POST92 POST94)

for (( i=0; i<${#IMAGE[@]} ; i++)) ; do
  echo "number:$i"
  NAME=$(eval echo \${${IMAGE[$i]}[0]})
#pull release and upgrade images
  docker pull registry.access.redhat.com/$NAME:latest
  RIMAGE_ID=`echo $(docker images |grep registry.access.redhat.com/$NAME)|cut -d' ' -f3`
  docker pull brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888/$NAME:latest
  UIMAGE_ID=`echo $(docker images |grep brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888/$NAME)|cut -d' ' -f3`

#check image ID
  if [ "$RIMAGE_ID" != "$UIMAGE_ID" ];then
      docker tag -f registry.access.redhat.com/$NAME:latest virt-openshift-05.lab.eng.nay.redhat.com:5001/ose-release/$NAME:latest
      docker push virt-openshift-05.lab.eng.nay.redhat.com:5001/ose-release/$NAME:latest
#check push successful
      DIFF=`cat push.log |grep sha256 |cut -d ':' -f1,2,3`
        if [ "$DIFF" != "latest: digest: sha256" ];then 
            echo "push release $NAME failed"
        else 
            echo "push release $NAME successfully"
        fi
        rm -f push.log

      docker tag -f brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888/$NAME:latest virt-openshift-05.lab.eng.nay.redhat.com:5001/ose-upgrade/$NAME:latest
      docker push virt-openshift-05.lab.eng.nay.redhat.com:5001/ose-upgrade/$NAME:latest
#check push successful
      DIFF=`cat push.log |grep sha256 |cut -d ':' -f1,2,3`
        if [ "$DIFF" != "latest: digest: sha256" ];then
           echo "push upgrade $NAME failed"
        else 
           echo "push upgrade $NAME successfully"
        fi 
        rm -f push.log

#delete release images
     docker rmi -f $RIMAGE_ID
  else
    echo "$NAME images ID are the same"
  fi
done
