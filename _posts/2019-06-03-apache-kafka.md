---
layout: post
title: Apache Kafka 笔记
date: 2019-06-03
tags: 技术笔记
author: shareif
---

[TOC]

## 概念

* Producer - Topic - Consumer

  kafka消息流模式遵循从Producer到Topic到Consumer的模式，其中Producer为生产者，像特定的Topic中发布消息，Consumer为消费者，持续不断的向Topic轮询消费消息。

* Client - Broker

  kafka中Producer和Consumer都叫Client(客户端)，而存储消息的kafka server称为Broker，作为数据掮客。

* Replication (Leader - Follower)

  高可用的实现机制，数据备份，Leader作为一个信任根，消息的读写操作都由Leader提供，而Follower目前仅从Leader不断同步数据作为备份节点，不对外提供读。

* Partitioning

  高扩展的实现机制，将一个庞大的消息队列（Topic）分成若干个区，消费者通过从不同分区读数据来缓解单个分区的性能压力，达到负载均衡。

* Log Segment

  在一个分区之中，kafka还会分成若干Log Segment，通过不断老化可以被老化的Segment来释放磁盘空间，这样既能利用空间，同时也能利用顺序I/O带来的高效。

* 消费模型(点对点，发布订阅)

  消费模型建立在消费者组的基础上，一个消费者组通常是用来消费同一个Topic的消息，如果Topic有分区，则每个分区最多会被这个消费者组中的某一个消费者消费。如果这个消费者组只有一个消费者，则为点对点模型，如果有多个消费者组消费同一个Topic，则为发布订阅模型，注意发布订阅模型中，同一个消息可以被多个消费者组消费。

* 重平衡

  重平衡会在一个消费者组中某个消费者挂掉之后发生，这个挂掉的消费者所消费的分区将被重新分配给这个组中的其他消费者。

* Offset & Consumer Offset

  Offset是站在Broker的角度的，表示的是一个消息队列已经被消费到了哪里。而Consumer Offset是站在消费者的角度记录消费者消费了哪些记录。

## Kafka版本

* 0.7版本，上古版本，Kafka开源时的版本
* 0.8版本，加入了副本机制
* 0.9版本，增加基础安全/权限功能，引入kafka connect
* 0.10版本，引入Kafka Streams
* 0.11版本，提供幂等性Producer API，事务API，重构Kafka消息格式（推荐版本0.11.0.3）
* 1.0版本/2.0版本，Kafka Streams改进。

## Kafka部署平台

|          | Linux                      | Windows                   |
| -------- | -------------------------- | ------------------------- |
| I/O模型  | epoll (多路复用->信号驱动) | select (I/O多路复用)      |
| 网络传输 | Zero Copy                  | Zero Copy (>Java8 60版本) |
| 社区     | Bug尽力修复                | Bug基本不会修复           |

Kafka使用顺序读写磁盘，基本规避了机械磁盘的劣势：随机读写慢，所以可以使用机械磁盘，同时Kafka在软件层面提供了高可靠高可用，也没有必要使用RAID。当然土豪请随意。

 kafka producer速率可以监控这个JMX指标：

```shell
kafka.producer:type=[consumer|producer|connect]-node-metrics,client-id=([-.\w]+),node-id=([0-9]+)
```

## Kafka集群参数

### Broker参数

官方详细文档 -> [Broker Config](http://kafka.apache.org/0110/documentation.html#brokerconfigs)

#### 存储

* log.dirs：指定了 Broker 需要使用的若干个文件目录路径，用逗号分隔多个路径，最好每个路径在不同物理磁盘中，比起单块磁盘，能够提高数据吞吐量。Kafka 1.1版本后，提供了Failover故障转移功能，如果Broker使用了多个磁盘，那坏掉磁盘的数据可以转移到正常磁盘中，而且Broker还能正常工作。

#### ZooKeeper（分布式协调框架）

是一个分布式协调框架，负责协调管理并保存 Kafka 集群的所有元数据信息，比如集群都有哪些 Broker 在运行、创建了哪些 Topic，每个 Topic 都有多少分区以及这些分区的 Leader 副本都在哪些机器上等信息。

* zookeeper.connect：`zk1:2181,zk2:2181,zk3:2181`

#### 通信

* listeners: `协议名://主机名:端口号` 告诉别人，如何访问开放的kafka服务
* advertised.listeners：对外发布的listeners，如果此配置没有指定，则会使用`listeners`配置
* listener.security.protocol.map：对于自定义的协议名，需要指定此值声明安全协议

#### Topic管理

* auto.create.topics.enable：是否允许自动创建Topic
* unclean.leader.election.enable：是否允许unclean leader选举，建议false，防止落后副本当选Leader
* auto.leader.rebalance.enable：是否允许强制更换leader，建议false，防止没必要的leader切换

#### 数据留存

* log.retention.{hours|minutes|ms}：Kafka数据留存时间，超过这个时间会被删除
* log.retention.bytes：消息保存的总磁盘大小，超过会删除

* message.max.bytes：kafka最大能接受的消息大小。

### Topic 参数

Topic级别参数会覆盖全局Broker级别参数值

* retention.ms：Topic消息留存时间，默认7天
* retention.bytes：为该Topic预留多大的磁盘空间
* max.message.bytes：该Topic能够接受最大消息大小

#### 在创建Topic时指定Topic级别参数

```shell
bin/kafka-topics.sh --bootstrap-server localhost:9092 \
    --create --topic transaction \
    --partitions 1 \
    --replication-factor 1 \
    --config retention.ms=15552000000 \
    --config max.message.bytes=5242880
```

#### 修改Topic级别参数（推荐）

```shell
bin/kafka-configs.sh --zookeeper localhost:2181 \
     --entity-type topics \
     --entity-name transaction \
     --alter --add-config max.message.bytes=10485760
```

### JVM 参数

在启动kafka之前设置两个环境变量：

* KAFKA_HEAP_OPTS：指定堆大小，堆大小的最佳实践经验值为6G
* KAFKA_JVM_PERFORMANCE_OPTS：指定GC，推荐G1，Java8需显示指定G1

比如：

```shell
export KAFKA_HEAP_OPTS=--Xms6g  --Xmx6g
export  KAFKA_JVM_PERFORMANCE_OPTS= -server -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:+ExplicitGCInvokesConcurrent -Djava.awt.headless=true
bin/kafka-server-start.sh config/server.properties
```

### 操作系统参数

* 文件描述符：`ulimit -n 1000000`，调大这个值，防止出现 Too many open files 的错误。
* 文件系统类型：XFS > ext4
* swap：设置成1，防止触发无预警OOM Killer，设置成1，方便问题定位。
* 提交时间：即页缓存刷到硬盘的时间，默认5s，可以稍微调大，虽然有数据丢失风险，但kafka的备份冗余机制可以降低风险。

## Kafka生产者

### 分区

#### 分区策略

##### 自定义分区策略

需要实现`org.apache.kafka.clients.producer.Partitioner`接口：

```java
int partition(String topic, Object key, byte[] keyBytes, Object value, byte[] valueBytes, Cluster cluster);
```

其中，前4个参数属于消息数据，最后一个参数给出了集群的信息，比如集群的topic数，broker数等。实现完成这个接口之后，显示的指定`partitioner.class`参数为类的全量名称。

自定义分区策略，可以根据业务不同灵活的选择合适的分区策略，比如按照地理位置进行分区，从消息中获取到key值，或者将地理位置标记封装进key中，再根据key值保序，那相同key值的消息必然进入同一个分区。或者更极端的，一个地理位置的消息占用一个分区，比如中国每个省或者直辖市占用一个分区，只要实现Partitioner接口，就可以轻松完成这种独占分区的策略。

##### 轮询策略（默认）

顾名思义，就是逐一遍历。

##### 随机策略

随机的将消息发布到不同的分区中，（还不如轮询

##### 消息键保序策略（Key-ordering）

实现接口

```java
int partition(String topic, Object key, byte[] keyBytes, Object value, byte[] valueBytes, Cluster cluster){
  List<PartitionInfo> partitions = cluster.partitionsForTopic(topic);
    return Math.abs(key.hashCode()) % partitions.size();
}
```

统一个key的所有消息都能进入到同一个分区中。

### 压缩

#### 消息格式

Kafka 0.11.0.x版本之后，消息被称为record，消息格式版本为v2，`magic=2` 。官方描述参考 [Message Format](http://kafka.apache.org/0110/documentation.html#messageformat)。消息的写操作总是以batch为单位，一个batch可以包含一个或多个record。

v2版本的消息CRC校验操作，移到了batch层次，不必再逐条record进行CRC校验，同时压缩方式也从之前的逐条压缩后放入batch中，变为将整个batch进行压缩。

#### 压缩方式

kafka能够进行压缩操作的地方有两个，一个是Producer，一个是Broker，而Consumer一般只用解压缩。如果Producer和Broker使用同一种压缩方法（默认Broker跟随Producer），则Broker不会再进行任何压缩，原样保存数据，而一旦Broker端指定了一种不一样的压缩方法，则会引发重新压缩的操作，带来不必要的CPU损耗。

在kafka 2.1.0 之前，kafka支持三种压缩算法：GZIP，Snappy，LZ4，之后的版本开始支持zstd压缩算法。

| 压缩方法     | 压缩比 | 压缩速度 | 解压速度  |
| ------------ | ------ | -------- | --------- |
| zstd 1.3.4   | 2.877  | 470 MB/s | 1280 MB/s |
| lz4 1.8.1    | 2.101  | 750 MB/s | 3700 MB/s |
| snappy 1.1.4 | 2.091  | 530 MB/s | 1800 MB/s |
| zlib 1.2.11  | 2.743  | 110 MB/s | 400 MB/s  |

#### 幂等Producer

幂等，在Kafka中，指的是多次操作产生同一个结果，更具体一点讲，就是确保消息精确提交一次，Broker能对幂等Producer发送的消息进行去重，保证同一个消息只成功提交了一次。设置幂等Producer的方法很简单：

```java
props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG， true)
```

幂等Producer的局限在于：它只能保证单会话、单Topic、单分区上的幂等。如果跨会话了，或跨Topic、分区了，仍然无法保证幂等，即还是有可能产生重复的消息。

#### 事务Producer

事务保证能将多个消息原子性的写入到多个分区中，即这一批消息中，如果其中有一个消息没有写入到其对应的分区，那这个操作就是失败的，其他已经成功写入的消息也会被“回滚”。换句话说，这一批消息的写入，要么全部成功，要么全部失败。设置事务Producer的方法：

```java
props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG， true);
props.put(ProducerConfig.TRANSACTIONAL_ID_CONFIG, "test.producer");
```

在提交原子消息时：

```java
producer.initTransactions();
try {
            producer.beginTransaction();
            producer.send(record1);
            producer.send(record2);
            producer.commitTransaction();
} catch (KafkaException e) {
            producer.abortTransaction();
}
```

同时，要保证消费者无法看到提交失败的消息，也要做如下设置：

```java
props.put(ConsumerConfig.ISOLATION_LEVEL_CONFIG, "read_committed");
```

## Kafka 消费者

### 消费者组

Kafka的消费者组绝对是kafka中最为重要的概念之一，借助Kafka的消费者组，kafka非常优雅的实现了点对点发布模型和订阅发布模型，偏颇一点讲，借助Kafka消费者组，kafka既能实现一个消息只被一个消费者消费，又能实现一个消息被多个消费者消费。

* 一个消费者组下面可以有多个消费者实例
* 一个消费者组由Group ID 唯一标识
* 一个分区的消息，只能被消费者组中的某一个消费者消费，当然可以被多个消费者组消费。

更简单一点理解，一个消费者组可以看成是一个业务逻辑的横向扩展，一个消息只要被这个特定的业务逻辑消费一次就够了，一个消费者组中的多个实例是消费性能的横向扩展。而对于不同消费者组，是不同的业务逻辑，所以不同的业务逻辑是可以同时消费同一个消息的。理想情况下，一个消费者组中的消费者实例个数 <= 订阅的Topics的所有分区数总和。多出的实例将会处于无分区消费的尴尬状态。

当所以消费者都属于同一个消费者组时，Kafka的一个消息不可能被重复消费，其实际上就是点对点的模型，当所有消费者的消费者组都不一样时，这时候所有消费者消费的都是同样的消息，其实际上就是发布订阅的模型。

PS. Kafka消费者组中的成员变化会导致kafka进行重平衡操作，此操作性能影响极大，所以尽量避免动态的消费者变化

## 无消息丢失配置

kafka只对已提交的消息负责。

### 最佳实践

* 不要使用`producer.send(msg)`方法，而要使用带回调的`producer.send(msg, callback)`方法。
  
* 设置`ack=all`，ack是producer的一个参数，该参数表示当多少个副本broker接受消息时认为消息已提交成功。
Headset

* 设置retries为较大的值，以防瞬时故障导致的消息发送失败，比如网络抖动。
  
* 设置`unclean.leader.election.enable=false`，放止在有些落后的副本Broker通过竞选当上leader，造成数据丢失。

* 设置`replication.factor >=3`，该参数为Broker端参数，表示设置多少个副本。

* 设置`min.insync.replicas>1`，这是Broker端参数，表示消息至少被写入到多少个副本Broker才能被定义为已提交。

* 设置`replication.factor > min.insync.replicas`，如果两者相等，则一旦一个副本GG，那整个分区就GG了。

* 设置`enable.auto.commit=false`，该参数会自动提交offset，在某些异常情况，消费者如果没有消费完消息异常退出，就会造成数据丢失。

## 客户端拦截器

kafka客户端才有拦截器，broker没有拦截器。

要使用kafka拦截器，需要实现其提供的接口，消费者需要实现`org.apache.kafka.clients.consumer.ConsumerInterceptor`，生产者需要实现`org.apache.kafka.clients.producer.ProducerInterceptor`。

## Kafka如何管理TCP连接

* KafkaProducer 实例创建时启动 Sender 线程，从而创建与 bootstrap.servers 中所有 Broker 的 TCP 连接。
* KafkaProducer 实例首次更新元数据信息之后，还会再次创建与集群中所有 Broker 的 TCP 连接。
* 如果 Producer 端发送消息到某台 Broker 时发现没有与该 Broker 的 TCP 连接，那么也会立即创建连接。
* 如果设置 Producer 端 connections.max.idle.ms 参数大于 0，则步骤 1 中创建的 TCP 连接会被自动关闭；如果设置该参数 =-1，那么步骤 1 中创建的 TCP 连接将无法被关闭，从而成为“僵尸”连接。



## Demo

```java
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.springframework.stereotype.Service;

import java.util.Properties;
import java.util.concurrent.*;

@Slf4j
@Service
public class KafkaProducerService extends ThreadPoolExecutor {
    static Properties props = new Properties();

    static KafkaProducer<String, String> producer = null;

    // 核心池大小
    static int corePoolSize = 5;

    // 最大值
    static int maximumPoolSize = 20;

    // 无任务时存活时间
    static long keepAliveTime = 60;

    // 时间单位
    static TimeUnit timeUnit = TimeUnit.SECONDS;

    // 阻塞队列
    static BlockingQueue blockingQueue = new LinkedBlockingQueue();

    // 线程池
    static ExecutorService service = null;

    // 配置项
    static {
        // 自定义分区类
        props.put(ProducerConfig.PARTITIONER_CLASS_CONFIG, "class qualifed name.");
        // Kafka服务端的主机名和端口号
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "node22:9092,node22:9092,node23:9092");
        // 等待所有副本节点的应答
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        // 消息发送最大尝试次数
        props.put(ProducerConfig.RETRIES_CONFIG, 5);
        // 一批消息处理大小
        props.put(ProducerConfig.BATCH_SIZE_CONFIG, 16384);
        // 增加服务端请求延时
        props.put(ProducerConfig.LINGER_MS_CONFIG, 1);
        // 发送缓存区内存大小
        props.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 33554432);
        // key序列化
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
        // value序列化
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
        // 增加拦截器
        props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, "com.example.websocketdemo.kafka.interceptor.CustomProducerInterceptor");
    }

    public KafkaProducerService(int corePoolSize, int maximumPoolSize, long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue) {
        super(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue);
    }

    public KafkaProducerService(int corePoolSize, int maximumPoolSize, long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue, ThreadFactory threadFactory) {
        super(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue, threadFactory);
    }

    public KafkaProducerService(int corePoolSize, int maximumPoolSize, long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue, RejectedExecutionHandler handler) {
        super(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue, handler);
    }

    public KafkaProducerService(int corePoolSize, int maximumPoolSize, long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue, ThreadFactory threadFactory, RejectedExecutionHandler handler) {
        super(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue, threadFactory, handler);
    }

    public KafkaProducerService() {
        super(corePoolSize, maximumPoolSize, keepAliveTime, timeUnit, blockingQueue);
    }

    public boolean sendRecord(ProducerRecord record) {
        Future result = this.submit(new ProducerRunnable(new KafkaProducer<String, String>(props), record));

        try {
            return (Boolean) result.get(10, timeUnit);
        } catch (TimeoutException te) {
            log.error("sending record to kafka timeout.", te.getStackTrace());
            result.cancel(true);
        } catch (InterruptedException ie) {
            log.error("sending record to kafka interrupted. {}", ie.getStackTrace());
        } catch (ExecutionException ee) {
            log.error("sending record to kafka execution failed. {}", ee.getStackTrace());
        }
        return false;
    }

    public boolean sendRecord(String value, String topic) {
        ProducerRecord<String, String> record = new ProducerRecord<>(topic, value);
        return sendRecord(record);
    }

    class ProducerRunnable implements Runnable {
        private KafkaProducer<String, String> producer;
        private ProducerRecord<String, String> record;

        public ProducerRunnable(KafkaProducer<String, String> producer, ProducerRecord<String, String> record) {
            this.producer = producer;
            this.record = record;
        }

        @Override
        public void run() {
            producer.send(record, (metadata, exception) -> {
                if (exception != null) {
                    log.error("message send failed. {}", exception.getStackTrace());
                    return;
                }

                if (metadata != null) {
                    log.info("message send successfully, {}", metadata.toString());
                }
            });
        }
    }
}
```
