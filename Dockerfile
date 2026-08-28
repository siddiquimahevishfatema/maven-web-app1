FROM tomcat:latest
MAINTAINER Mahevish <mahevish@oracle.com>
EXPOSE 8080
COPY target/maven-app.war /usr/local/tomcat/webapps/maven-app.war
