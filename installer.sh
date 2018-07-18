#!/bin/bash

INSTALLER_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $INSTALLER_HOME/variables.conf
source $INSTALLER_HOME/util.sh

install_all_dependencies() {
    #echo 'deb http://pkg.mytestbed.net/ubuntu precise/ ' >> /etc/apt/sources.list \
    apt-get update
    apt-get install -y --force-yes --reinstall \
       curl \
       dnsmasq \
       git \
       libsqlite3-dev \
       libreadline6-dev \
       libyaml-dev \
       libxmlsec1-dev \
       ntp \
       python \
       syslinux \
       xmlsec1 \
       wget \
       zlib1g-dev

    install_virtinst
    install_frisbee
    install_omf_dependencies
    check_and_install_ruby
}

install_virtinst() {
    apt-get update
    apt-get install -y --force-yes --reinstall virtinst
}

install_frisbee() {
    echo "skipping frisbee installation..."
    #echo 'deb http://pkg.mytestbed.net/ubuntu precise/ ' >> /etc/apt/sources.list \
    #&& apt-get update
    #apt-get install -y --force-yes --reinstall \
    #   frisbee
}

install_omf_dependencies() {
    check_and_install_ruby
    apt-get install -y --force-yes --reinstall \
        build-essential \
        libssl-dev
}

check_linux_version() {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        ...
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        ...
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

check_and_install_start_command() {
    check_linux_version
    check_for_start_command
#    if [ "$OS" = "Ubuntu" ] && [ "$VER" = "16.04" ] && [ "$START_INSTALLED" = "no" ]; then
#        echo "This machine uses Ubuntu 16.04 and needs to install the upstart-sysv so that the OMF modules work."
#        echo "This operation will reboot your machine. After the reboot, run the installer.sh script again."
#        echo "Do you want to install the upstart-sysv package? (Y/n)"
#        read option
#        case $option in
#            Y|y) install_start_command;;
#            N|n) ;;
#            *) install_start_command;;
#        esac
#    fi
}

check_for_start_command() {
    if [ $(dpkg-query -W -f='${Status}' upstart-sysv 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
      START_INSTALLED="no"
    else
      START_INSTALLED="yes"
    fi
}

install_start_command() {
    echo "SKIPPING upstart-sysv package instalation"
#    echo "INSTALLING upstart-sysv package"
#    apt-get install upstart-sysv -y
#    update-initramfs -u
#    reboot
#    WILL_REBOOT="yes"
}

check_and_install_ruby() {
    if [ ! "$(which ruby)" ]; then
        install_ruby
    elif [[ "$(ruby -v)" != *$RUBY_VERSION* ]]; then
        echo "This machine has a ruby installation with version:"
        ruby -v
        echo "Do you want to substitute it by version $RUBY_VERSION? (Y/n)"
        read option
        case $option in
            Y|y) check_before_remove_ruby && install_ruby;;
            N|n) ;;
            *) check_before_remove_ruby && install_ruby;;
        esac
    fi
}

install_ruby() {
    apt-get update
    apt-get install -y --force-yes g++ \
        gcc \
        make \
        libc6-dev \
        libreadline6-dev \
        zlib1g-dev \
        libssl-dev \
        libyaml-dev \
        libsqlite3-dev \
        sqlite3 \
        autoconf \
        libgmp-dev \
        libgdbm-dev \
        libncurses5-dev \
        automake \
        libtool \
        bison \
        pkg-config \
        libffi-dev \
        wget

    cd /tmp \
           && wget http://ftp.ruby-lang.org/pub/ruby/2.3/ruby-2.3.2.tar.gz \
           && tar -xvzf ruby-2.3.2.tar.gz \
           && cd ruby-2.3.2/ \
           && ./configure --prefix=/usr/local \
           && make \
           && make install \
           && rm -rf /tmp/ruby

    gem install bundler --no-ri --no-rdoc
}

check_before_remove_ruby() {
    echo "Are you sure you want to remove ruby? (Y/n)"
    read option
    case $option in
        Y|y) remove_ruby;;
        *) ;;
    esac
}

remove_ruby() {
    rm -rf /usr/local/lib/ruby
    rm -rf /usr/lib/ruby
    rm -f /usr/local/bin/ruby
    rm -f /usr/bin/ruby
    rm -f /usr/local/bin/irb
    rm -f /usr/bin/irb
    rm -f /usr/local/bin/gem
    rm -f /usr/bin/gem
}

download_omf() {
    cd /root
    if [ "$(ls -A $OMF_HOME)" ]; then
        rm -rf $OMF_HOME
    fi
    git clone -b amqp https://github.com/LABORA-UFG/omf.git
}

install_omf() {
    if [[ $1 == "--install_dependencies" ]]; then
        install_all_dependencies
    fi

    download_omf

    #Install omf_common
    install_omf_common_gem

    #Install omf_rc
    install_omf_rc_gem "--configure"

    #Install omf_ec
    install_omf_ec_gem
}

install_omf_common_gem() {
    if [[ $1 == "--install_dependencies" ]]; then
        install_omf_dependencies
    fi

    download_omf

    cd $OMF_COMMON_HOME
    gem build omf_common.gemspec
    gem install omf_common-*.gem
}

update_omf_common_gem() {
    install_omf_common_gem
}

install_omf_basic_dependencies() {
    apt-get update
    check_and_install_ruby
    install_omf_dependencies
}

install_omf_rc_dependencies() {
    install_omf_basic_dependencies
    install_virtinst
}

install_omf_rc_gem() {
    if [[ $1 == "--install_dependencies" ]]; then
        install_omf_rc_dependencies
    fi

    omf_common_installed=$(gem list -i omf_common)
    echo "OMF Common already installed? $omf_common_installed"
    if [ "$omf_common_installed" == "false" ]; then
        echo "INSTALLING OMF COMMON GEM"
        install_omf_common_gem
    fi

    download_omf

    cd $OMF_RC_HOME
    gem build omf_rc.gemspec
    gem install omf_rc-*.gem


    HAS_TO_CONFIG=0

    for i in $*; do
       if [[ "$i" == "--configure" ]]; then
           HAS_TO_CONFIG=1
       fi
    done
    if [[ "$HAS_TO_CONFIG" == 1 ]]; then
        install_omf_rc -i -c
    fi

}

update_omf_rc_gem() {
    install_omf_rc_gem # the /etc/omf_rc/conf.yml file is not replaced without --configure
}

install_omf_ec_gem() {
    if [[ $1 == "--install_dependencies" ]]; then
        install_omf_basic_dependencies
    fi

    download_omf

    if [ ! $(gem list -i omf_common) ]; then
        install_omf_common_gem
    fi

    cd $OMF_COMMON_HOME
    gem build omf_common.gemspec
    gem install omf_common-*.gem

    cd $OMF_EC_HOME
    gem build omf_ec.gemspec
    gem install omf_ec-*.gem

    HAS_TO_CONFIG=0

    for i in $*; do
       if [[ "$i" == "--configure" ]]; then
           HAS_TO_CONFIG=1
       fi
    done
    if [[ "$HAS_TO_CONFIG" == 1 ]]; then
        install_omf_ec -c
    fi

}

update_omf_ec_gem() {
    install_omf_ec_gem # the /etc/omf_ec/conf.yml file is not replaced without --configure
}

remove_omf() {
    gem uninstall omf_common -a -I --force -x
    gem uninstall omf_rc -a -I --force -x
    gem uninstall omf_ec -a -I --force -x
}

install_openflow_related_rcs() {
    if [[ $1 == "--install_dependencies" ]]; then
        install_omf_basic_dependencies
    fi

    install_omf_rc_gem
    cd /root
    git clone -b master https://github.com/LABORA-UFG/omf_rc_openflow.git
    cd $OMF_OPENFLOW_RCS_HOME
    gem build omf_rc_openflow.gemspec
    gem install omf_rc_openflow-*.gem

    #this installation file comes from the omf_rc_openflow gem
    install_openflow_rcs

    cd /root
    rm -rf $OMF_OPENFLOW_RCS_HOME
}

install_flowvisor_rc_gem() {
    if [[ $1 == "--install_dependencies" ]]; then
        install_omf_basic_dependencies
    fi

    install_omf_rc_gem
    cd /root
    git clone -b master https://github.com/LABORA-UFG/omf_rc_openflow.git
    cd $OMF_OPENFLOW_RCS_HOME
    gem build omf_rc_openflow.gemspec
    gem install omf_rc_openflow-*.gem

    #this installation file comes from the omf_rc_openflow gem
    install_flowvisor_rc -i -c

    cd /root
    rm -rf $OMF_OPENFLOW_RCS_HOME
}

remove_openflow_rcs() {
    gem uninstall omf_rc_openflow -a -I --force -x

    rm -rf /etc/omf_rc/flowvisor_proxy_conf.yaml
    rm -rf /etc/omf_rc/ovs_proxy_conf.yaml
    rm -rf /usr/local/bin/run_openflow_rcs.sh
    rm -rf /usr/local/bin/run_openflow_proxies
}

install_broker() {
    if [[ $1 == "--install_dependencies" ]]; then
        install_all_dependencies
        install_omf_common_gem
    fi
    #if $OMF_SFA_HOME directory does not exist or is empty
    if [ ! "$(ls -A $OMF_SFA_HOME)" ] || [ ! "$(ls -A /root/.omf)" ]; then
        echo "###############INSTALLATION OF THE MODULES###############"
        #Start of Broker installation
        echo "###############GIT CLONE OMF_SFA REPOSITORY###############"
        cd /root
        echo $(pwd)
        echo $OMF_SFA_HOME
        git clone -b amqp https://github.com/LABORA-UFG/omf_sfa.git
        cd $OMF_SFA_HOME
        echo "###############INSTALLING OMF_SFA###############"
        if ! gem list bundler -i; then
            gem install bundler --no-ri --no-rdoc
        fi
        bundle install

        echo "###############RAKE DB:MIGRATE###############"
        rake db:migrate

        echo "###############CREATING DEFAULT SSH KEY###############"
        ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""

        ##START OF CERTIFICATES CONFIGURATION
        create_broker_cerficates
        ##END OF CERTIFICATES CONFIGURATION

        echo "###############CONFIGURING OMF_SFA AS UPSTART SERVICE###############"
        if [ "$OS" = "Ubuntu" ] && [ "$VER" != "14.04" ]; then
            echo "Configuring systemd..."
            cp init/omf-sfa.service /etc/systemd/system/
            chmod 664 /etc/systemd/system/omf-sfa.service
            systemctl daemon-reload
            systemctl enable omf-sfa.service
        else
            echo "Configuring upstart..."
            cp init/omf-sfa.conf /etc/init/ && sed -i '/chdir \/root\/omf\/omf_sfa/c\chdir \/root\/omf_sfa' /etc/init/omf-sfa.conf
        fi
        #End of Broker installation

        create_broker_rabbitmq_user
    fi
}

create_broker_cerficates() {
    echo "###############CONFIGURING OMF_SFA CERTIFICATES###############"
    mkdir -p /root/.omf/trusted_roots
    omf_cert.rb --email root@$DOMAIN -o /root/.omf/trusted_roots/root.pem --duration 50000000 create_root
    omf_cert.rb -o /root/.omf/am.pem  --geni_uri URI:urn:publicid:IDN+$AM_SERVER_DOMAIN+user+am --email am@$DOMAIN --resource-id amqp://am_controller@$XMPP_DOMAIN --resource-type am_controller --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
    omf_cert.rb -o /root/.omf/user_cert.pem --geni_uri URI:urn:publicid:IDN+$AM_SERVER_DOMAIN+user+root --email root@$DOMAIN --user root --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_user

    openssl rsa -in /root/.omf/am.pem -outform PEM -out /root/.omf/am.pkey
    openssl rsa -in /root/.omf/user_cert.pem -outform PEM -out /root/.omf/user_cert.pkey
}

remove_broker() {
    service omf-sfa stop
    rm -rf $OMF_SFA_HOME
    rm /etc/init/omf-sfa.conf
    rm -rf /root/.omf/*.pem
    rm -rf /root/.omf/*.pkey
    rm -rf /root/.omf/trusted_roots

    if [ $1 == "-y" ]; then
        remove_nitos_rcs --purge
    else
        echo "NITOS Testbed RCs will not work without Broker. Do you want to uninstall them too? (Y/n)"
        read option
        case $option in
            Y|y) remove_nitos_rcs --purge;;
            *) ;;
        esac
    fi
}

install_nitos_rcs() {
    if ! gem list nitos_testbed_rc -i; then
        #Start of NITOS Testbed RCs installation
        install_frisbee
        echo "###############INSTALLING NITOS TESTBED RCS###############"
        cd /root
        git clone -b amqp https://github.com/LABORA-UFG/nitos_testbed_rc.git
        cd $NITOS_HOME
        gem build nitos_testbed_rc.gemspec
        gem install nitos_testbed_rc-2.0.5.gem

        install_ntrc

#        if [ "$1" == "--configure" ]; then
#            $INSTALLER_HOME/configure.sh
#            cp -r /tmp/testbed-files/etc/nitos_testbed_rc /etc/
#        fi

        ##START OF CERTIFICATES CONFIGURATION
        echo "###############CONFIGURING NITOS TESTBED RCS CERTIFICATES###############"
        omf_cert.rb -o /root/.omf/user_factory.pem --email user_factory@$DOMAIN --resource-type user_factory --resource-id amqp://user_factory@$XMPP_DOMAIN --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
        omf_cert.rb -o /root/.omf/cm_factory.pem --email cm_factory@$DOMAIN --resource-type cm_factory --resource-id amqp://cm_factory@$XMPP_DOMAIN --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
        omf_cert.rb -o /root/.omf/frisbee_factory.pem --email frisbee_factory@$DOMAIN --resource-type frisbee_factory --resource-id amqp://frisbee_factory@$XMPP_DOMAIN --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
        cp -r /root/.omf/trusted_roots/ /etc/nitos_testbed_rc/
        ##END OF CERTIFICATES CONFIGURATION
        #End of NITOS Testbed RCs installation
        rm -rf $NITOS_HOME

        create_rabbitmq_user cm_proxy testbed
        create_rabbitmq_user frisbee_proxy testbed
        create_rabbitmq_user script_user testbed
        create_rabbitmq_user user_proxy testbed
    fi
}

remove_nitos_rcs() {
    stop ntrc
    gem uninstall nitos_testbed_rc -a -I --force -x

    if [ "$1" == "--purge" ]; then
        rm -rf /root/.omf/
    else
        rm -rf /root/.omf/etc
    fi

    rm -rf /etc/nitos_testbed_rc
    rm -rf /usr/local/bin/run_ntrc.sh
}

configure_testbed() {

    ##START OF - COPING CONFIGURATION FILES
    echo "###############COPYING CONFIGURATION FILES TO THE RIGHT PLACE###############"
    cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bkp
    cd $INSTALLER_HOME
    cp -r /tmp/testbed-files/* /
    ##END OF - COPING CONFIGURATION FILES

    #START OF PXE CONFIGURATION
    echo "###############PXE CONFIGURATION###############"
    ln -s /usr/lib/syslinux/pxelinux.0 /tftpboot/
    ln -s /tftpboot/pxelinux.cfg/pxeconfig /tftpboot/pxelinux.cfg/01-00:03:1d:0c:23:46
    ln -s /tftpboot/pxelinux.cfg/pxeconfig /tftpboot/pxelinux.cfg/01-00:03:1d:0c:47:48

    cp /etc/hosts /etc/hosts.bkp
    cat /root/hosts >> /etc/hosts
    rm /root/hosts
    #END OF PXE CONFIGURATION
}

remove_testbed_configuration() {
    cp /etc/dnsmasq.conf.bkp /etc/dnsmasq.conf
    rm /etc/dnsmasq.d/testbed.conf
    rm -rf /root/omf-images
    rm -rf /root/ec-test
    rm -rf /tftpboot
}

start_broker() {
    echo "Executing omf_sfa"
    service omf-sfa start
}

start_nitos_rcs() {
    echo "Executing NITOS Testbed RCs"
    service ntrc start
}

insert_nodes() {
    /root/omf_sfa/bin/create_resource -t node -c /root/omf_sfa/bin/conf.yaml -i /root/resources.json
}

install_amqp_server() {
    apt-get install -y --force-yes rabbitmq-server
}

remove_amqp_server() {
    apt-get remove -y --force-yes --purge rabbitmq-server
}

download_baseline_image() {
    mkdir /root/omf-images
    wget https://www.dropbox.com/s/2bgqpebadxb8fgh/root-node-icarus1-05_07_2016_01%3A51.ndz?dl=0 -O /root/omf-images/baseline.ndz
}

install_oml2() {
    echo "deb http://download.opensuse.org/repositories/home:/cdwertmann:/oml/xUbuntu_14.04/ ./" >> /etc/apt/sources.list
    echo "deb-src http://download.opensuse.org/repositories/home:/cdwertmann:/oml/xUbuntu_14.04/ ./" >> /etc/apt/sources.list

    apt-get update
    apt-get install -y --force-yes oml2-server
}

remove_oml2() {
    apt-get remove -y --force-yes --purge oml2-server
}

#TODO remove configuration in /etc/hosts
remove_testbed() {
    echo -n "Do you really want to remove all Testbed components? This will remove all configuration files too. (y/N)"
    read option
    case $option in
        Y|y) ;;
        N|n) exit ;;
        *) exit;;
    esac

    remove_nitos_rcs
    remove_broker -y
    remove_amqp_server
    remove_omf
    remove_oml2
    remove_testbed_configuration
}

create_broker_rabbitmq_user() {
    rabbitmqctl add_user testbed testbed
    rabbitmqctl set_permissions -p / testbed ".*" ".*" ".*"
}

create_rabbitmq_user() {
    rabbitmqctl add_user "$1" "$2"
    rabbitmqctl set_permissions -p / "$1" ".*" ".*" ".*"
}

install_testbed() {
    install_all_dependencies

    #$INSTALLER_HOME/configure.sh

    install_omf
    install_amqp_server
    install_broker
    install_nitos_rcs
    configure_testbed

    service dnsmasq restart

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

reinstall_testbed() {
    printMessage "REMOVING THE TESTBED"
    if [ -d "$OMF_SFA_HOME" ] || [ -d "/root/.omf" ]; then
        remove_testbed
    fi
    printMessage "INSTALLING THE TESTBED"
    install_testbed
}

main() {
    check_and_install_start_command
    if [ "$WILL_REBOOT" = yes ]; then
        exit 0
    fi

    $INSTALLER_HOME/configure.sh

    echo "------------------------------------------"
    echo "Options:"
    echo
    echo "1. Install Testbed"
    echo "2. Uninstall Testbed"
    echo "3. Reinstall Testbed"
    echo "4. Install only Broker"
    echo "5. Uninstall Broker"
    echo "6. Install only NITOS Testbed RCs"
    echo "7. Uninstall NITOS Testbed RCs"
    echo "8. Insert resources into Broker"
    echo "9. Download baseline.ndz"
    echo "10. Configure omf_rc on Icarus nodes"
    echo "11. Install openflow related rcs"
    echo "12. Uninstall openflow related rcs"
    echo "13. Install OMF"
    echo "14. Install OMF RC"
    echo "15. Install OMF EC"
    echo "16. Install Flowvisor RC"
    echo "17. (Re)create broker certificates"
    echo "18. Update OMF RC"
    echo "19. Update OMF EC"
    echo "20. Update OMF Commom"
    echo "21. Exit"
    echo
    echo -n "Choose an option..."
    read option
    case $option in
    1) install_testbed ;;
    2) remove_testbed ;;
    3) reinstall_testbed ;;
    4) install_broker "--install_dependencies" ;;
    5) remove_broker ;;
    6) install_nitos_rcs "--configure";;
    7) remove_nitos_rcs ;;
    8) insert_nodes ;;
    9) download_baseline_image ;;
    10) $INSTALLER_HOME/configure-icarus.sh ;;
    11) install_openflow_related_rcs "--install_dependencies" ;;
    12) remove_openflow_rcs ;;
    13) install_omf "--install_dependencies" ;;
    14) install_omf_rc_gem "--install_dependencies" "--configure";;
    15) install_omf_ec_gem "--install_dependencies" "--configure";;
    16) install_flowvisor_rc_gem "--install_dependencies" ;;
    17) create_broker_cerficates ;;
    18) update_omf_rc_gem ;;
    19) update_omf_ec_gem ;;
    20) update_omf_common_gem;;
    *) exit ;;
    esac
}

main
