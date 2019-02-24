FROM jenkins/jenkins:2.150.3

RUN /usr/local/bin/install-plugins.sh git github matrix-auth workflow-aggregator docker-workflow blueocean credentials-binding startup-trigger
# RUN /usr/local/bin/install-plugins.sh sse-gateway:1.17 pubsub-light:1.6 git github docker-workflow blueocean credentials-binding startup-trigger

ENV JENKINS_UC_DOWNLOAD=http://mirrors.jenkins-ci.org
ENV JENKINS_USER admin
ENV JENKINS_PASS admin

# Skip initial setup
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/
COPY default-user.groovy /usr/share/jenkins/ref/init.groovy.d/
VOLUME /var/jenkins_home
COPY jobs/ /var/jenkins_home/jobs/
COPY config.xml /var/jenkins_home/config.xml
USER root
RUN mkdir -p ${ITEM_ROOTDIR}/builds