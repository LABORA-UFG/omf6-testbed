omf6-testbed
============

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
    16. Exit
    
    Choose an option...
    
Option number 1 will install in a single machine the rabbitmq server, the [omf6 modules](https://github.com/LABORA-UFG/omf) (omf_common, omf_rc, omf_ec), the [NITOS testbed RCs](https://github.com/LABORA-UFG/nitos_testbed_rc), and the Broker ([omf_sfa project](https://github.com/LABORA-UFG/omf_sfa)). That option will also install the OML server and download the icarus baseline image.
Option number 8 will insert at the Broker's inventory the icarus nodes configured in the [conf/nodes.conf](conf/nodes.conf) file. Option 10 will configure the RC on icarus nodes. The other options are quite intuitive.

Modules Explanation
-------------------
