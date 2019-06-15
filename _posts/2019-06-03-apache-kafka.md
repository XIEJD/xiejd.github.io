---
layout: post
title: Apache Kafka 原理和用途学习笔记
date: 2019-06-03
tags: 技术笔记
author: shareif
---

## 简介

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