#!/bin/sh

function _set_neighbors(){
    return 0;
}

function _rebuild_common(){
    sudo /etc/init.d/httpd reload > /dev/null 2>&1;
}

function _add_common_host(){
    grep -q "${host} " /etc/httpd/conf/virtualhosts_http.conf && return 0;
    host_num=`cat /etc/httpd/conf/virtualhosts_http.conf|grep BalancerMember | awk '{print $3}' | sed 's/route=//g' | sort -n | tail -n1`;
    let "host_num+=1";
    sed -i '/<Proxy balancer:\/\/myclusterhttp>/a BalancerMember http:\/\/'${host}' route='${host_num}'' /etc/httpd/conf/virtualhosts_http.conf;
    sed -i '/<Proxy balancer:\/\/myclusterajp>/a BalancerMember ajp:\/\/'${host}':8009' /etc/httpd/conf/virtualhosts_ajp.conf;
    sed -i "s/worker.balancer.balance_workers.*/&node-s${host_num},/" /etc/httpd/conf/worker.properties
    echo '#####Configuration section for worker.node-s'${host_num}'' >> /etc/httpd/conf/worker.properties;
    echo 'worker.node-s'${host_num}'.type=ajp13' >> /etc/httpd/conf/worker.properties;
    echo 'worker.node-s'${host_num}'.host'=${host} >> /etc/httpd/conf/worker.properties;
    echo 'worker.node-s'${host_num}'.port=8009' >> /etc/httpd/conf/worker.properties;
}

function _remove_common_host(){
    [ -n "${host}" ] && sed -i '/'${host}'/d' /etc/httpd/conf/virtualhosts_http.conf && sed -i '/'${host}'/d' /etc/httpd/conf/virtualhosts_ajp.conf;
    local worker_string=`cat /etc/httpd/conf/worker.properties|grep ${host}|grep -o "worker.node-s[0-9]*"`
    local node_string=`cat /etc/httpd/conf/worker.properties|grep ${host}|grep -o "node-s[0-9]*"`;
    [ -n "${worker_string}" ] && sed -i '/'${worker_string}'/d' /etc/httpd/conf/worker.properties;
    [ -n "${node_string}" ] && sed -i 's/'${node_string}',//' /etc/httpd/conf/worker.properties;
}

function _add_host_to_group(){
    return 0;
}

function _build_cluster(){
    return 0;
}

function _unbuild_cluster(){
    return 0;
}

function _clear_hosts(){
    return 0;
}

function _reload_configs(){
    return 0;
}

