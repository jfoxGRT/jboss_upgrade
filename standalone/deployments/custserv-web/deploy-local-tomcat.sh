#!/bin/bash

rm -rf ${SAMI_TOMCAT_HOME}/webapps/custserv.war
rm -rf ${SAMI_TOMCAT_HOME}/webapps/custserv
rm -rf ${SAMI_TOMCAT_HOME}/conf/Catalina/localhost/custserv.xml

cp target/custserv.war ${SAMI_TOMCAT_HOME}/webapps/custserv.war
