---
title: mosquitto confs
date: 2019-12-28
---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Global Options](#global-options)
- [Listener Specified Options](#listener-specified-options)
- [SSL/TLS Options](#ssltls-options)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Global Options

```properties
#通常在精确匹配后，又匹配上通配符会收到重复消息
allow_duplicate_messages true

#禁止特殊字符'+' or '#'，此过程在acl鉴权之前
auth_plugin_deny_special_chars true

#订阅变化、保留消息、收到的消息、队列中的消息自动保存到磁盘间隔时间(秒)
#0表示仅当mosquitto退出或者收到SIGUSR1信号时保存
autosave_interval 1800

#当true，将把autosave_interval当成数量，当订阅变化、消息等超过这个数量时，保存到磁盘
#当false，将吧autosave_interval当成时间
autosave_on_changes false

#
check_retain_source

#clientId前缀校验，非'secure-'前缀的clientId将被判定为非法ID
clientid_prefixes secure-

#是否输出连接信息日志
connection_messages true

#额外的配置文件加载路径，可配置多个
include_dir dir1

#日志输出目的地
#如果值为topic，将输出到系统主题中$SYS/broker/log/[D|E|W|N|I|M]
#如果值为file，输出到文件，比如：log_dest file /path/to/your/log
log_dest [stderr|syslog|topic|stdout|file]

#日志相关参数
log_facility
log_timestamp
log_timestamp_format
log_type

#消息相关参数
max_inflight_bytes
max_inflight_messages
max_packet_size
max_queued_bytes
max_queued_messages
message_size_limit
queue_qos0_messages false
retain_available true

#链路相关参数
max_keepalive
set_tcp_nodelay false

#内存限制
memory_limit

#持久化
persistence false
retained_persistence
persistence_file
persistence_location
persistent_client_expiration

#进程
pid_file
user

#系统主题，每10秒刷新一侧订阅层次结构
sys_interval 10

#非主流参数
upgrade_outgoing_qos false
```

## Listener Specified Options

```properties
#监听端口相关参数
per_listener_settings true

#安全相关参数
password_file

#细粒度鉴权
acl_file /your/aclfile/path

#Pre Shared Key file
psk_file

#是否允许匿名模式，如果允许，客户端可以不用带username和password
allow_anonymous true

#允许Broker自动生成clientId
allow_zero_length_clientid true

#当Broker生成clientId时，自动生成的ID的前缀
auto_id_prefix auto-

#鉴权相关参数
auth_opt_*

#定义鉴权插件
auth_plugin /your/path/to/plugin.so

#######################################
#######################################

bind_address
bind_interface
http_dir
listener
max_connections
maximum_qos
max_topic_alias
mount_point
port 
protocol
socket_domain
user_username_as_clientid
websockets_log_level
websockets_headers_size
```

## SSL/TLS Options

```properties
cafile
capath
certfile
ciphers
crlfile
dhparamfile
keyfile
require_certificate
tls_engine
```
