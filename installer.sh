#!/bin/bash

INSTALLER_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $INSTALLER_HOME/variables.conf

install_dependencies() {
    echo 'deb http://pkg.mytestbed.net/ubuntu precise/ ' >> /etc/apt/sources.list \
    && apt-get update
    apt-get install -y --force-yes \
       build-essential \
       curl \
       dnsmasq \
       frisbee \
       git \
       libsqlite3-dev \
       libreadline6-dev \
       libssl-dev \
       libyaml-dev \
       libxml2-dev \
       libxmlsec1-dev \
       libxslt-dev \
       links2 \
       ntp \
       python \
       syslinux \
       xmlsec1 \
       wget \
       zlib1g-dev

    cd /tmp \
       && wget http://ftp.ruby-lang.org/pub/ruby/2.2/ruby-2.2.3.tar.gz \
       && tar -xvzf ruby-2.2.3.tar.gz \
       && cd ruby-2.2.3/ \
       && ./configure --prefix=/usr/local \
       && make \
       && make install \
       && rm -rf /tmp/ruby

    gem install bundler --no-ri --no-rdoc
}

install_omf() {
    cd /root
    git clone -b amqp https://github.com/viniciusgb4/omf.git
    cd $OMF_COMMON_HOME
    gem build omf_common.gemspec
    gem install omf_common-*.gem

    cd $OMF_RC_HOME
    gem build omf_rc.gemspec
    gem install omf_rc-*.gem

    cd $OMF_EC_HOME
    gem build omf_ec.gemspec
    gem install omf_ec-*.gem

    cd /root
    rm -rf $OMF_HOME
}

install_broker() {
    #if $OMF_SFA_HOME directory does not exist or is empty
    if [ ! "$(ls -A $OMF_SFA_HOME)" ] || [ ! "$(ls -A /root/.omf)" ]; then
        echo "###############INSTALLATION OF THE MODULES###############"
        #Start of Broker installation
        echo "###############GIT CLONE OMF_SFA REPOSITORY###############"
        cd /root
        echo $(pwd)
        echo $OMF_SFA_HOME
        git clone -b amqp https://github.com/viniciusgb4/omf_sfa.git
        cd $OMF_SFA_HOME
        echo "###############INSTALLING OMF_SFA###############"
        bundle install

        echo "###############RAKE DB:MIGRATE###############"
        rake db:migrate

        echo "###############CREATING DEFAULT SSH KEY###############"
        ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""

        ##START OF CERTIFICATES CONFIGURATION
        echo "###############CONFIGURING OMF_SFA CERTIFICATES###############"
        mkdir -p /root/.omf/trusted_roots
        omf_cert.rb --email root@$DOMAIN -o /root/.omf/trusted_roots/root.pem --duration 50000000 create_root
        omf_cert.rb -o /root/.omf/am.pem  --geni_uri URI:urn:publicid:IDN+$AM_SERVER_DOMAIN+user+am --email am@$DOMAIN --resource-id amqp://am_controller@$XMPP_DOMAIN --resource-type am_controller --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
        omf_cert.rb -o /root/.omf/user_cert.pem --geni_uri URI:urn:publicid:IDN+$AM_SERVER_DOMAIN+user+root --email root@$DOMAIN --user root --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_user

        openssl rsa -in /root/.omf/am.pem -outform PEM -out /root/.omf/am.pkey
        openssl rsa -in /root/.omf/user_cert.pem -outform PEM -out /root/.omf/user_cert.pkey
        ##END OF CERTIFICATES CONFIGURATION

        echo "###############CONFIGURING OMF_SFA AS UPSTART SERVICE###############"
        cp init/omf-sfa.conf /etc/init/ && sed -i '/chdir \/root\/omf\/omf_sfa/c\chdir \/root\/omf_sfa' /etc/init/omf-sfa.conf
        #End of Broker installation
    fi
}

uninstall_broker() {
    bundle exec ruby -I lib lib/omf-sfa/am/am_server.rb stop
    rm -rf $OMF_SFA_HOME
    echo "Uninstall NITOS Testbed RCs?"
    read option
    case $option in
        y) unistall_nitos_rcs ;;
        Y) unistall_nitos_rcs ;;
        *) ;;
    esac
}

install_nitos_rcs() {
    if ! gem list nitos_testbed_rc -i; then
        #Start of NITOS Testbed RCs installation
        echo "###############INSTALLING NITOS TESTBED RCS###############"
        cd /root
        git clone -b amqp https://github.com/viniciusgb4/nitos_testbed_rc.git
        cd $NITOS_HOME
        gem build nitos_testbed_rc.gemspec
        gem install nitos_testbed_rc-2.0.5.gem

        install_ntrc

        ##START OF CERTIFICATES CONFIGURATION
        echo "###############CONFIGURING NITOS TESTBED RCS CERTIFICATES###############"
        omf_cert.rb -o /root/.omf/user_factory.pem --email user_factory@$DOMAIN --resource-type user_factory --resource-id amqp://user_factory@$XMPP_DOMAIN --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
        omf_cert.rb -o /root/.omf/cm_factory.pem --email cm_factory@$DOMAIN --resource-type cm_factory --resource-id amqp://cm_factory@$XMPP_DOMAIN --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
        omf_cert.rb -o /root/.omf/frisbee_factory.pem --email frisbee_factory@$DOMAIN --resource-type frisbee_factory --resource-id amqp://frisbee_factory@$XMPP_DOMAIN --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
        cp -r /root/.omf/trusted_roots/ /etc/nitos_testbed_rc/
        ##END OF CERTIFICATES CONFIGURATION
        #End of NITOS Testbed RCs installation
        rm -rf $NITOS_HOME
    fi
}

uninstall_nitos_rcs() {
    gem unistall nitos_testbed_rc
    rm -rf /root/.omf
    rm -rf /etc/nitos_testbed_rc
}

install_ec() {
    gem install omf_ec --no-ri --no-rdoc
}

uninstall_ec() {
    gem unistall omf_ec
}

configure_testbed() {

    ##START OF - COPING CONFIGURATION FILES
    echo "###############COPYING CONFIGURATION FILES TO THE RIGHT PLACE###############"
    cp -rf /etc/dnsmasq.conf /etc/dnsmasq.conf.bkp
    cd $INSTALLER_HOME
    cp -r /tmp/testbed-files/* /
    ##END OF - COPING CONFIGURATION FILES

    #START OF PXE CONFIGURATION
    echo "###############PXE CONFIGURATION###############"
    ln -s /usr/lib/syslinux/pxelinux.0 /tftpboot/
    ln -s /tftpboot/pxelinux.cfg/pxeconfig /tftpboot/pxelinux.cfg/01-00:03:1d:0c:23:46
    ln -s /tftpboot/pxelinux.cfg/pxeconfig /tftpboot/pxelinux.cfg/01-00:03:1d:0c:47:48

    cat /root/hosts >> /etc/hosts
    #END OF PXE CONFIGURATION
}

start_broker() {
    echo "Executing omf_sfa"
    start omf-sfa
}

start_nitos_rcs() {
    echo "Executing NITOS Testbed RCs"
    start ntrc
}

insert_nodes() {
    /root/omf_sfa/bin/create_resource -t node -c /root/omf_sfa/bin/conf.yaml -i /root/resources.json
}

log_broker() {
    tail -f /var/log/omf-sfa.log
}

install_amqp_server() {
    apt-get install  -y --force-yes rabbitmq-server
}

download_baseline_image() {
    mkdir /root/omf-images
    wget https://www.dropbox.com/s/2bgqpebadxb8fgh/root-node-icarus1-05_07_2016_01%3A51.ndz?dl=0 -O /root/omf-images/baseline.ndz
}

install_oml2() {
    echo "deb http://download.opensuse.org/repositories/home:/cdwertmann:/oml/xUbuntu_14.04/ ./" >> /etc/apt/sources.list
    echo "deb-src http://download.opensuse.org/repositories/home:/cdwertmann:/oml/xUbuntu_14.04/ ./" >> /etc/apt/sources.list

    apt-get update
    apt-get install oml2-server
}

install_testbed() {
    install_dependencies

    $INSTALLER_HOME/configure.sh

    install_omf
    install_amqp_server
    install_broker
    install_nitos_rcs
    configure_testbed
    #install_ec

    service dnsmasq restart

    #########################START OF CREATE USER RABBITMQ#####################
    rabbitmqctl add_user testbed testbed
    rabbitmqctl set_permissions -p / testbed ".*" ".*" ".*"

    rabbitmqctl add_user cm_user testbed
    rabbitmqctl set_permissions -p / cm_user ".*" ".*" ".*"

    rabbitmqctl add_user frisbee_user testbed
    rabbitmqctl set_permissions -p / frisbee_user ".*" ".*" ".*"

    rabbitmqctl add_user script_user testbed
    rabbitmqctl set_permissions -p / script_user ".*" ".*" ".*"

    rabbitmqctl add_user user_proxy_user testbed
    rabbitmqctl set_permissions -p / user_proxy_user ".*" ".*" ".*"
    #########################END OF CREATE USER RABBITMQ#####################

    start_broker
    start_nitos_rcs

    echo "Waiting for services start up..."
    sleep 5s

    echo -n "Do you want to install the OML Server? (Y/n)"
    read option
    case $option in
        Y|y) install_oml2 ;;
        N|n) ;;
        *) install_oml2 ;;
    esac

    echo -n "Do you want to insert the resources into Broker? (Y/n)"
    read option
    case $option in
        Y|y) insert_nodes ;;
        N|n) ;;
        *) insert_nodes;;
    esac

    echo -n "Do you want to configure omf_ec on Icarus nodes? (Y/n)"
    read option
    case $option in
        Y|y) $INSTALLER_HOME/configure-icarus.sh ;;
        N|n) ;;
        *) $INSTALLER_HOME/configure-icarus.sh ;;
    esac

    echo -n "Do you want to download the baseline image for icarus nodes? (Y/n)"
    read option
    case $option in
        Y|y) download_baseline_image ;;
        N|n) exit ;;
        *) download_baseline_image;;
    esac
}

main() {
    echo "------------------------------------------"
    echo "Options:"
    echo
    echo "1. Install Testbed"
    echo "2. Install only Broker"
    echo "3. Install only NITOS Testbed RCs"
    echo "4. Uninstall Broker"
    echo "5. Uninstall NITOS Testbed RCs"
    echo "6. Insert resources into Broker"
    echo "7. Install EC"
    echo "8. Uninstall EC"
    echo "9. Download baseline.ndz"
    echo "10. Configure omf_rc on Icarus nodes"
    echo "11. Exit"
    echo
    echo -n "Choose an option..."
    read option
    case $option in
    1) install_testbed ;;
    2) install_broker ;;
    3) install_nitos_rcs ;;
    4) uninstall_broker ;;
    5) uninstall_nitos_rcs ;;
    6) insert_nodes ;;
    7) install_ec ;;
    8) uninstall_ec ;;
    9) download_baseline_image ;;
    10) $INSTALLER_HOME/configure-icarus.sh ;;
    *) exit ;;
    esac
}

main