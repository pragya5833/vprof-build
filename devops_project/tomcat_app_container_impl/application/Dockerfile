FROM openjdk:8 AS build
RUN apt update && apt install maven -y
# Copy pom.xml to the image
COPY pom.xml /home/app/pom.xml
COPY ./src /home/app/src
#RUN mvn -f /home/app/pom.xml verify clean 

# Copy the source code 

RUN mvn clean install -f /home/app/pom.xml -Dmaven.test.skip

# Install Tomcat    & openjdk 8 (openjdk has java and javac)
FROM tomcat:8-jre11
RUN rm -rf /usr/local/tomcat/webapps/* &&\
      rm -rf conf/context.xml

# Copy source files to tomcat folder structure
COPY --from=build /home/app/target/vprofile-v1.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
# CMD ["catalina.sh", "run"]