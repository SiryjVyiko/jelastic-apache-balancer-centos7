#!/bin/sh

function _set_neighbors(){
    return 0;
}

function rebuildCommon(){
    local RELOAD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};echo;`;
    $CARTRIDGE_HOME/versions/$Version/usr/bin/varnishadm -T 127.0.0.1:81 -S $CARTRIDGE_HOME/secret vcl.load $RELOAD $CARTRIDGE_HOME/vcl/default.vcl > /dev/null 2>&1;
    $CARTRIDGE_HOME/versions/$Version/usr/bin/varnishadm -T 127.0.0.1:81 -S $CARTRIDGE_HOME/secret vcl.use $RELOAD > /dev/null 2>&1;
}

function addCommonHostConfig(){
    local existing_host=`cat $CARTRIDGE_HOME/vcl/default.vcl | grep $host`;
    [ -n "$existing_host" ] && return 0;
    local host_num=`cat $CARTRIDGE_HOME/vcl/default.vcl | grep "backend serv" | awk '{print $2}' | sed 's/serv//g' | sort -n | tail -n1`;
    let "host_num+=1";
    sed -i '/import directors;/a backend serv'$host_num' { .host = "'${host}'"; .port = "80"; .probe = { .url = "\/"; .timeout = 30s; .interval = 60s; .window = 5; .threshold = 2; } }' $CARTRIDGE_HOME/vcl/default.vcl;
    sed -i '/new myclust = directors.*;/a myclust.add_backend(serv'$host_num', 1);' $CARTRIDGE_HOME/vcl/default.vcl;
    sed -i '/backend default { .host = "127.0.0.1"/d' $CARTRIDGE_HOME/vcl/default.vcl;
    local RELOAD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};echo;`;
    $CARTRIDGE_HOME/versions/$Version/usr/bin/varnishadm -T 127.0.0.1:81 -S $CARTRIDGE_HOME/secret vcl.load $RELOAD $CARTRIDGE_HOME/vcl/default.vcl > /dev/null 2>&1;
    $CARTRIDGE_HOME/versions/$Version/usr/bin/varnishadm -T 127.0.0.1:81 -S $CARTRIDGE_HOME/secret vcl.use $RELOAD > /dev/null 2>&1;
}

function removeCommonHostConfig(){
    local target_host=`cat $CARTRIDGE_HOME/vcl/default.vcl | grep ${host} | awk '{print $2}'`;
    [ -z "$target_host" ] && return 0;
    sed -i '/'${target_host}'/d' $CARTRIDGE_HOME/vcl/default.vcl;
    local least_hosts=`cat $CARTRIDGE_HOME/vcl/default.vcl | grep "backend serv"`;
    [ -z "$least_hosts" ] && sed -i '/import directors;/a backend default { .host = "127.0.0.1"; .port = "80"; }' $CARTRIDGE_HOME/vcl/default.vcl;
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

