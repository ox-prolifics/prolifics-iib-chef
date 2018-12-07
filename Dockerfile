FROM docker.io/prolifics/pbc-iib10-jenkins

USER root

# RUN yum -y -q update
RUN  yum -y -q install wget rpm \
     && rm -rf /var/lib/yum/lists/* \ 
     && mkdir /tmp/install \
     && cd /tmp/install \
     && wget -q --content-disposition "https://packages.chef.io/files/stable/chef-server/12.18.14/el/7/chef-server-core-12.18.14-1.el7.x86_64.rpm" \
     && rpm -ivh chef-server-core-12.18.14-1.el7.x86_64.rpm

# do not add any comments after ADD or COPY or you get: "no such file or directory"
COPY install /tmp/install 

RUN cp /tmp/install/scripts/run_chef_server.sh /usr/bin/  \
    && chmod 755 /usr/bin/run_chef_server.sh

#RUN /scripts/install_chef_server.sh && \
#    mv /scripts/image_metadata.txt /etc/docker_image_metadata.txt && \
#    && run recipes
#    /scripts/cleanup.sh
#
#EXPOSE 443
#ENTRYPOINT ["/bin/bash", "-c"]
#CMD ["/usr/bin/run_chef_server.sh"]
CMD ["bash"]
