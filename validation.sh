#!/bin/bash

INSTALLER_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ICARUS_NAMES=()

read_icarus_names() {
    oldIFS=$IFS

    while read line; do
        IFS=', ' read -r -a array <<< "$line"
        if [[ ${array[0]} != *"#"* ]]; then
            ICARUS_NAMES+=(${array[0]})
        fi
        IFS=$'n'
    done < $INSTALLER_HOME/conf/nodes.conf
    IFS=$old_IFS
}

function print_array_with_separator { local IFS="$1"; shift; echo "$*"; }

look_node_is_up() {
    if ping -c 1 $1 &> /dev/null; then
      echo 1
    else
      echo 0
    fi
}

execute_omf6_stat() {
    timeout 10 omf6 stat -t $(print_array_with_separator , "${ICARUS_NAMES[@]}")
}

execute_omf6_tell_on() {
    omf6 tell -a on -t $(print_array_with_separator , "${ICARUS_NAMES[@]}")
}

execute_omf6_tell_off() {
    omf6 tell -a off -t $(print_array_with_separator , "${ICARUS_NAMES[@]}")
}

execute_omf6_tell_reset() {
    omf6 tell -a reset -t $(print_array_with_separator , "${ICARUS_NAMES[@]}")
}

execute_omf6_load() {
    for node in "${ICARUS_NAMES[@]}"; do
        timeout 120 omf6 load -t $node
    done
}

execute_omf6_save() {
    for node in "${ICARUS_NAMES[@]}"; do
        timeout 120 omf6 save -n $node
    done
}

execute_tutorial() {
    omf_ec -u amqp://testbed:lab251@10.129.11.206 exec --oml_uri tcp:10.129.11.206:3003 /root/ec-test/tutorial.rb
}

main() {
    read_icarus_names

    echo "------------------------------------------"
    echo "Options:"
    echo
    echo "1. Configure omf_rc on Icarus nodes"
    echo "2. Test stat command"
    echo "3. Test tell on command"
    echo "4. Test tell off command"
    echo "5. Test tell reset command"
    echo "6. Test load command"
    echo "7. Test save command"
    echo "8. Execute tutorial experiment"
    echo "9. Exit"
    echo
    echo -n "Choose an option..."
    read option
    case $option in
    1) $INSTALLER_HOME/configure-icarus.sh ;;
    2) execute_omf6_stat;;
    3) execute_omf6_tell_on ;;
    4) execute_omf6_tell_off ;;
    5) execute_omf6_tell_reset ;;
    6) execute_omf6_load ;;
    7) execute_omf6_save ;;
    8) execute_tutorial ;;
    *) exit ;;
    esac

}

main