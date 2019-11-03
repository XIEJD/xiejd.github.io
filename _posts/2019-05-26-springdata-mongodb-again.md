---
title: SpringData MongoDb Again
date: 2019-05-26
---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Basic](#basic)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Basic

* MongoDb Docker

  ```shell
  docker run -d -p 27017:27017 -v 本地db文件夹路径:/data/db mongo:latest
  ```

  其中`-p 27017:27017`表示将本地端口27017映射到容器端口27017，`-v`后的参数表示将本地的数据文件映射到容器中，以便数据库数据复用。

* Configuration

  ```java
  @Configuration
  public class MongoDbConfig extends AbstractMongoConfiguration {
      @Override
      protected String getDatabaseName() {
          return "v2xdb";
      }
  
      @Override
      public Mongo mongo() throws Exception {
          return new MongoClient("localhost", 27017);
      }
  }
  ```

  一个常规的Java配置。

* Compass

  MongoDb的可视化管理界面，方便分析语句，同时自带聚合操作界面，并且是同类GUI中最好看的。。。
