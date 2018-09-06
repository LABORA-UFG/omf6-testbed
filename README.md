This project has a set of scripts and configuration files to install all necessary modules to create a complete omf6 testbed.

Installation Guide
==================

Notes
-----
This script was tested in Ubuntu 14.04. It should work in later versions, but we not guarantee.

Environment
-----------

TODO here goes a description of a simple testbed environment with a figure.

Prerequirements
---------------
First, you need to install git and clone the project. For now, the indicated branch is amqp. To maintain a pattern, use the root user and clone the project at **/root**.

    # apt-get install git
    # cd /root
    # git clone -b amqp https://github.com/LABORA-UFG/omf6-testbed.git

Configuration
-------------
Before execute the installer script, it is necessary to change some configuration files.

* At variables.conf: you have to change the values of the variables DOMAIN, AM_SERVER_DOMAIN and XMPP_DOMAIN to the domain of your institution. For example, the value of UFG is ufg.br.

* At conf/nodes.conf: you have to put a list of icarus nodes with its ips and macs.

* At conf/interface-service-map.conf: you have to configure the interface interface of the control network.

* At conf/testbed.conf: you have to put the DNS configuration of the nodes in your testbed.


Installation
------------
To install the testbed modules, you have to run the [installer.sh](installer.sh) script. The script will show a list of options that allows you to install the modules separately or to install all modules in a single machine (option 1).

Inside the omf6-testbed project folder, run:

    # ./installer.sh

The following options will be prompted. To choose an option you have just to write its number and press Enter.

    ------------------------------------------
    Options:
    
    1. Install Testbed
    2. Uninstall Testbed
    3. Reinstall Testbed
    4. Install only Broker
    5. Uninstall Broker
    6. Install only NITOS Testbed RCs
    7. Uninstall NITOS Testbed RCs
    8. Insert resources into Broker
    9. Download baseline.ndz
    10. Configure omf_rc on Icarus nodes
    11. Install openflow related rcs
    12. Uninstall openflow related rcs
    13. Install OMF
    14. Install OMF RC
    15. Install OMF EC
    16. Install Flowvisor RC
    17. (Re)create broker certificates
    18. Update OMF RC
    19. Update OMF EC
    20. Update OMF Commom
    21. Install PostgreSQL
    22. Create Inventory DB in PostresSQL
    23. Exit  
    
    Choose an option...
    
Option number 1 will install in a single machine the rabbitmq server, the [omf6 modules](https://github.com/LABORA-UFG/omf) (omf_common, omf_rc, omf_ec), the [NITOS testbed RCs](https://github.com/LABORA-UFG/nitos_testbed_rc), and the Broker ([omf_sfa project](https://github.com/LABORA-UFG/omf_sfa)). That option will also install the OML server and download the icarus baseline image.
Option number 8 will insert at the Broker's inventory the icarus nodes configured in the [conf/nodes.conf](conf/nodes.conf) file. Option 10 will configure the RC on icarus nodes. The other options are quite intuitive.

Option 22 will create the inventory database (with all its tables) in PostgresSQL.

Flowvisor RC Configuration
-------------------

After install the Flowvisor RC, you need to edit the file /etc/omf_rc/flowvisor_proxy_conf.yaml. 

<pre>
#details to be used for the connection to the pubsub server
:pubsub:
  :protocol: amqp
  :username: testbed
  :password: testbed
  :server: <b>&lt;DOMAIN&gt;</b>

#operation mode for OmfCommon.init (development, production, etc)
:operationMode: development

:uid: <%= Socket.gethostname %>-fw

#The default arguments of the communication between this resource and the flowvisor instance
:flowvisor:
  #The version of the flowvisor that this resource is able to control
  :version: "FV version=flowvisor-<b>&lt;FLOWVISOR-VERSION&gt;</b>"

  :host: "localhost"
  :path: "/xmlrc"
  :port: "8080"
  #proxy_host: ""
  #proxy_port: ""
  :user: "fvadmin"
  :password: "<b>&lt;FVADMIN-PASSWORD&gt;</b>"
  :use_ssl: "true"
  :timeout: 60

#The default parameters of a new slice. The openflow controller is assumed to be
#in the same working station with flowvisor instance
:slice:
  :passwd: "1234"
  :email: "nothing@nowhere"
</pre>

* In \<DOMAIN\> you need to put the domain of your island.
* In \<FLOWVISOR-VERSION\> you need to put the version of the flowvisor running in your island. You may get this version by running the command:
  
  
    apt-cache policy flowvisor

The output of the command is something like this:

         1.0.2-1 0
            500 http://updates.onlab.us/debian/ stable/ Packages
         1.0.1-1 0
            500 http://updates.onlab.us/debian/ stable/ Packages
         1.0.0-1 0
            500 http://updates.onlab.us/debian/ stable/ Packages
     *** 0.8.17-3 0
            500 http://updates.onlab.us/debian/ stable/ Packages
            100 /var/lib/dpkg/status
         0.8.17-2 0
            500 http://updates.onlab.us/debian/ stable/ Packages
         0.8.17-1 0
            500 http://updates.onlab.us/debian/ stable/ Packages
         0.8.16-1 0
            500 http://updates.onlab.us/debian/ stable/ Packages
         0.8.15-1 0

The version of your flowvisor is the line marked with ***. In the above example, the value of <FLOWVISOR-VERSION> will be "0.8.17". 

* In \<FVADMIN-PASSWORD\> you need to put the password of the Flowvisor fvadmin user.

Modules Explanation
-------------------
