---
title: Spring Boot 学习笔记
date: 2019-06-02
---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [What](#what)
- [How](#how)
  - [自动配置](#%E8%87%AA%E5%8A%A8%E9%85%8D%E7%BD%AE)
  - [起步依赖](#%E8%B5%B7%E6%AD%A5%E4%BE%9D%E8%B5%96)
- [应用](#%E5%BA%94%E7%94%A8)
  - [WebSocket](#websocket)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## What

Spring Boot不是代码生成器，也不是服务器，它是一个能快速实现业务逻辑的编程框架，通过遵循Spring Boot的约定进行业务实现后，通常利用Maven进行项目的生命周期管理，编译打包成Jar包，然后给JVM运行。实际上利用Spring Boot和完全用纯Java实现业务的区别在于，Spring Boot能自动完成许多配置，帮你屏蔽掉很多不那么重要的代码实现，让程序快速上线。

## How

如何利用Spring Boot 快速开发

### 自动配置

核心：classpath

通过classpath上出现的配置类，自动进行配置

SpringFactoriesLoader加载配置类

所谓自动配置，其实是各种逻辑分支

### 起步依赖



## 应用

### WebSocket

* 客户端测试脚本(Python)

  ```python
  import asyncio
  import websockets
  import json
  
  async def test_ws_quote():
      async with websockets.connect('ws://localhost:8080/ws') as websocket:
          req = {"protocol":"history_req",'code':'XAGODS','type':'MINUTE','start_pos':'0','pos_num':'10'}
          await websocket.send(json.dumps(req))
          while True:
              quote = await websocket.recv()
              print(quote)
  
  asyncio.get_event_loop().run_until_complete(test_ws_quote())
  ```

* Java服务器端maven依赖，配置类，业务处理类

  ```xml
  <dependency>
  			<groupId>org.springframework.boot</groupId>
  			<artifactId>spring-boot-starter</artifactId>
  		</dependency>
  
  		<dependency>
  			<groupId>org.springframework.boot</groupId>
  			<artifactId>spring-boot-starter-websocket</artifactId>
  		</dependency>
  		<dependency>
  			<groupId>org.projectlombok</groupId>
  			<artifactId>lombok</artifactId>
  	</dependency>
  ```

  ```java
  @Slf4j
  @Configuration
  @EnableWebSocket
  public class MyWebSocketConfig implements WebSocketConfigurer {
  
      @Override
      public void registerWebSocketHandlers(WebSocketHandlerRegistry webSocketHandlerRegistry) {
          webSocketHandlerRegistry.addHandler(new MyWebSocketHandler(), "/ws")
                  .addInterceptors(new HttpSessionHandshakeInterceptor());
      }
  }
  ```

  ```java
  @Slf4j
  public class MyWebSocketHandler extends TextWebSocketHandler {
  
      @Override
      public void handleTextMessage(WebSocketSession session, TextMessage message) {
          log.info("new message: {}", message.getPayload());
          WebSocketMessage<String> webSocketMessage = new TextMessage("Hello world");
          try {
              for (int i = 0; i < 10; i++) {
                  session.sendMessage(webSocketMessage);
                  Thread.sleep(2000);
              }
          } catch (Exception e) {
              log.error("{}", e.getMessage());
          }
      }
  }
  ```
