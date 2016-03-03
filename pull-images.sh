#!/bin/bash
#This script is for pulling and pushing test images

RUBY20=(ruby-20-rhel7 openshift3/ruby-20-rhel7)
RUBY22=(ruby-22-rhel7 rhscl/ruby-22-rhel7)
NODEJS=(nodejs-010-rhel7 openshift3/nodejs-010-rhel7)
PERL516=(perl-516-rhel7 openshift3/perl-516-rhel7)
PERL520=(perl-520-rhel7 rhscl/perl-520-rhel7)
PYTHON27=(python-27-rhel7 rhscl/python-27-rhel7)
PYTHON33=(python-33-rhel7 openshift3/python-33-rhel7)
PYTHON34=(python-34-rhel7 rhscl/python-34-rhel7)
PHP55=(php-55-rhel7 openshift3/php-55-rhel7)
PHP56=(php-56-rhel7 rhscl/php-56-rhel7)
#TOMCAT7=(webserver30-tomcat7-openshift jboss-webserver-3/webserver30-tomcat7-openshift)
#TOMCAT8=(webserver30-tomcat8-openshift jboss-webserver-3/webserver30-tomcat8-openshift)
#EAP64=(eap64-openshift jboss-eap-6/eap64-openshift)
#AMQ62=(amq62-openshift jboss-amq-6/amq62-openshift)
JENKINS=(jenkins-1-rhel7 openshift3/jenkins-1-rhel7)
MYSQL55=(mysql-55-rhel7 openshift3/mysql-55-rhel7)
MYSQL56=(mysql-56-rhel7 rhscl/mysql-56-rhel7)
MONGO24=(mongodb-24-rhel7 openshift3/mongodb-24-rhel7)
MONGO26=(mongodb-26-rhel7 rhscl/mongodb-26-rhel7)
POST92=(postgresql-92-rhel7 openshift3/postgresql-92-rhel7)
POST94=(postgresql-94-rhel7 rhscl/postgresql-94-rhel7)

IMAGE=(RUBY20 RUBY22 NODEJS PERL516 PERL520 PYTHON27 PYTHON33 PYTHON34 PHP55 PHP56 JENKINS MYSQL55 MYSQL56 MONGO24 MONGO26 POST92 POST94)

for (( i=0; i<${#IMAGE[@]} ; i++)) ; do
  echo "number:$i"
  NAME=$(eval echo \${${IMAGE[$i]}[0]})
  REG=$(eval echo \${${IMAGE[$i]}[1]})
#pull release and upgrade images
  docker pull registry.access.redhat.com/$REG:latest
  RIMAGE_ID=`echo $(docker images |grep registry.access.redhat.com/$REG)|cut -d' ' -f3`
  docker pull brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888/$REG:latest
  UIMAGE_ID=`echo $(docker images |grep brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888/$REG)|cut -d' ' -f3`

#check image ID
   if [ "$RIMAGE_ID" != "$UIMAGE_ID" ];then
      echo "$NAME image updated, need testing"
      docker tag -f registry.access.redhat.com/$REG:latest virt-openshift-05.lab.eng.nay.redhat.com:5001/ose-release/$NAME:latest
      docker push virt-openshift-05.lab.eng.nay.redhat.com:5001/ose-release/$NAME:latest |tee -a push.log
#check push successful
      DIFF=`cat push.log |grep sha256 |cut -d ':' -f1,2,3`
        if [ "$DIFF" != "latest: digest: sha256" ];then 
            echo "push release $NAME failed"
        else 
            echo "push release $NAME successfully"
        fi
        rm -f push.log

      docker tag -f brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888/$REG:latest virt-openshift-05.lab.eng.nay.redhat.com:5001/ose-upgrade/$NAME:latest
      docker push virt-openshift-05.lab.eng.nay.redhat.com:5001/ose-upgrade/$NAME:latest |tee -a push.log
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
