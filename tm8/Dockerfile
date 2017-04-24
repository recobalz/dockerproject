FROM tomcat:8.0
MAINTAINER Dogthing
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
WORKDIR $CATALINA_HOME
VOLUME /code
ADD server.xml /usr/local/tomcat/conf
ADD context.xml /usr/local/tomcat/conf
ADD commons-pool2-2.2.jar /usr/local/tomcat/lib
ADD jedis-2.5.2.jar /usr/local/tomcat/lib
ADD redis-session-manager-2.1.1-SNAPSHOT.jar /usr/local/tomcat/lib
ADD redis-session-manager-with-dependencies-2.1.1-SNAPSHOT.jar /usr/local/tomcat/lib
ADD tomcat-redis-session-manager-2.0.0.jar /usr/local/tomcat/lib
EXPOSE 8080
CMD ["catalina.sh", "run"]
