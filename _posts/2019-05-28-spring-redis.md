---
title: Spring Redis
date: 2019-05-28
---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Basic](#basic)
  - [Maven依赖](#maven%E4%BE%9D%E8%B5%96)
  - [Redis Docker](#redis-docker)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Basic

### Maven依赖

* 对于SpringBoot Starter项目

  ```xml
  <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-redis</artifactId>
  </dependency>
  ```

* SpringData

  ```xml
  <!-- https://mvnrepository.com/artifact/org.springframework.data/spring-data-redis -->
  <dependency>
      <groupId>org.springframework.data</groupId>
      <artifactId>spring-data-redis</artifactId>
      <version>2.1.8.RELEASE</version>
  </dependency>
  ```

### Redis Docker

```shell
# 拉取镜像
docker pull redis
```

```shell
# 运行容器
docker run --name redis -d -p 6379:6379 redis
```

