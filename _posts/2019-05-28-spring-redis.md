---
layout: post
title: Spring Redis
date: 2019-05-28
tags: 技术笔记
author: shareif
---

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

