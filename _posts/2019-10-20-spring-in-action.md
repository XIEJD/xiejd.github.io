---
layout: post
title: Springboot 源码读后感
date: 2019-10-20
tags: 技术笔记
author: shareif
---

[TOC]

## Springboot 实战分享

### spring-boot-autoconfiguration

#### Jackson

Springboot默认的Json实现是Jackson，其对应的自动配置类为`JacksonAutoConfiguration`，同时通过`JacksonHttpMessageConvertersConfiguration` 配置HttpMessageConverter实现类用于Http请求中Json到POJO或者POJO到Json的转换。

JacksonAutoConfiguration的触发条件为存在类：`com.fasterxml.jackson.databind.ObjectMapper.class`。此配置将提供一些基础bean，比如`ObjectMapper` bean，`JsonComponentModule` bean。`ObjectMapper` bean是POJO和String转换的关键角色，而`JsonComponentModule` bean是配置由`@JsonComponent`定义的序列化和反序列化组件的关键角色。摘取源码中对`@JsonComponent`的注释：

```java
/**
 * {@link Component} that provides {@link JsonSerializer} and/or {@link JsonDeserializer}
 * implementations to be registered with Jackson when {@link JsonComponentModule} is in
 * use. Can be used to annotate {@link JsonSerializer} or {@link JsonDeserializer}
 * implementations directly or a class that contains them as inner-classes. For example:
 * 
 * 用法举例：
 * @JsonComponent
 * public class CustomerJsonComponent {
 *
 *     public static class Serializer extends JsonSerializer<Customer> {
 *         // ...
 *     }
 *
 *     public static class Deserializer extends JsonDeserializer<Customer> {
 *         // ...
 *     }
 *
 * }
 *
 */
```

JacksonHttpMessageConvertersConfiguration配置类可以提供两个bean，一个为`MappingJackson2HttpMessageConverter`，另一个为`MappingJackson2XmlHttpMessageConverter` 。前者解析媒体类型为`application/json`的数据，后者解析`application/xml`的数据。

`MappingJackson2HttpMessageConverter`实现了关键接口`GenericHttpMessageConverter` 用于将http请求转换为指定泛型类型的目标对象，将指定泛型类型的源对象转换为http响应。

总结，在Springboot启动后，就已经自动配置了一系列的bean来支持Json和POJO的转化，如果追求性能，完全不用自己再new一个ObjectMapper甚至多个ObjectMapper，`ObjectMapper`是线程安全的，可以放心大胆的用单例模式。同时由于注解`@JsonComponent` 和bean `JsonComponentModule` ,可以非常方便的自定义某些类型的序列化与反序列化方法。所以一个项目里面有多个`ObjectMapper`的理由是什么呢，甚至一个项目里有多个json实现库，比如gson、json-lib的意义是什么呢？

附：如何用Springboot的自己的`ObjectMapper`

```java
@Component
public class SpringUtil implements BeanFactoryAware {

    private static BeanFactory beanFactory;

    @Override
    public void setBeanFactory(BeanFactory beanFactory) throws BeansException {
        SpringUtil.beanFactory = beanFactory;
    }

    public static Object getBean(String beanName){
        return beanFactory.getBean(beanName);
    }

    public static Object getBean(Class<?> clazz) {
        return beanFactory.getBean(clazz);
    }
}
```

```java
@Slf4j
public class JacksonUtil {
    private static final ObjectMapper objectMapper;

    static {
        objectMapper = SpringUtil.getBean(ObjectMapper.class);
    }

    public static String toJson(Object obj) {
        Assert.notNull(obj, "Object must not be null");
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (Exception e) {
            log.error("convert to string failed, {}", e.getStackTrace());
            return null;
        }
    }

    public static <T> T fromJson(String json, Class<T> clazz) {
        Assert.notNull(json, "json string must not be null");
        Assert.notNull(clazz, "Class Type must not be null");

        try {
            return objectMapper.readValue(json, clazz);
        } catch (Exception e) {
            log.error("convert to obj failed, {}", e.getStackTrace());
            return null;
        }
    }
}
```



> References:
>
> 1. https://www.baeldung.com/spring-boot-jsoncomponent



#### Mongo

有两种Mongo自动配置类，一种是连接真实的mongo配置，一种是内存式的mongo配置。配置顺序为先配置内存式mongo（如果条件满足），再配置真实mongo。

1. 内存式mongo自动配置依赖：

   ```xml
   <!-- https://mvnrepository.com/artifact/de.flapdoodle.embed/de.flapdoodle.embed.mongo -->
   <dependency>
       <groupId>de.flapdoodle.embed</groupId>
       <artifactId>de.flapdoodle.embed.mongo</artifactId>
       <version>x.x.x</version>
       <scope>test</scope>
   </dependency>
   
   <!-- https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-data-mongodb -->
   <dependency>
       <groupId>org.springframework.boot</groupId>
       <artifactId>spring-boot-starter-data-mongodb</artifactId>
       <version>x.x.x.RELEASE</version>
   </dependency>
   ```

2. 真实mongo配置可以直接依赖：

   ```xml
   <!-- https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-data-mongodb -->
   <dependency>
       <groupId>org.springframework.boot</groupId>
       <artifactId>spring-boot-starter-data-mongodb</artifactId>
       <version>x.x.x.RELEASE</version>
   </dependency>
   ```

所以，当要使用mongodb时，引入`spring-boot-starter-data-mongodb`即可，如果需要用到内存式mongo，则在此基础上再引入`de.flapdoodle.embed.mongo`即可。AutoConfiguration就是这么叼，他能根据你引入的包来自动配置对应的bean。

首先，内存式mongo的自动配置类条件：

```java
@Configuration
@EnableConfigurationProperties({ MongoProperties.class, EmbeddedMongoProperties.class })
@AutoConfigureBefore(MongoAutoConfiguration.class)
@ConditionalOnClass({ MongoClient.class, MongodStarter.class })
public class EmbeddedMongoAutoConfiguration {}
```

该配置早于`MongoAutoConfiguration`配置：

```java
@Configuration
@ConditionalOnClass(MongoClient.class)
@EnableConfigurationProperties(MongoProperties.class)
@ConditionalOnMissingBean(type = "org.springframework.data.mongodb.MongoDbFactory")
public class MongoAutoConfiguration {}
```

`MongoAutoConfiguration`配置仅当容器内缺少`MongoDbFactory` bean时才会生效。