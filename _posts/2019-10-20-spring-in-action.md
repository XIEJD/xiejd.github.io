---
title: Springboot 源码读后感
date: 2019-10-20
---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [spring-boot-autoconfiguration](#spring-boot-autoconfiguration)
  - [Condition](#condition)
  - [Jackson](#jackson)
  - [Mongo](#mongo)
  - [Quartz](#quartz)
  - [Kafka](#kafka)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## spring-boot-autoconfiguration

### Condition

AutoConfiguration的condition包下面有一套条件注解，用来决定什么时候创建bean，基本上所有的自动配置类都会用到里面的注解来“智能”的决定什么时候创建bean。

| 注解                             | 解释                                                  |
| -------------------------------- | ----------------------------------------------------- |
| `@ConditionalOnBean`             | 当BeanFactory中存在某个bean时满足条件，可以匹配多个   |
| `@ConditionalOnClass`            | 当ClassPath下存在某个类时满足条件，可以匹配多个       |
| `@ConditionalOnCloudPlatform`    | 巴拉巴拉                                              |
| `@ConditionalOnExpression`       | 可以定义SpEL语句进行匹配                              |
| `@ConditinalOnJava`              | 匹配当前运行JVM版本                                   |
| `@ConditionalOnJndi`             |                                                       |
| `@ConditionalOnMissingBean`      |                                                       |
| `@ConditionalOnMissingClass`     |                                                       |
| `@ConditinalOnNotWebApplication` |                                                       |
| `@ConditionalOnProperty`         | 当满足某个属性时满足条件                              |
| `@ConditionalOnResource`         | 当classpath下存在某个资源文件时满足条件，可以匹配多个 |
| `@ConditinalOnSingleCandidate`   |                                                       |
| `@ConditinalOnWebApplication`    |                                                       |

举几个🌰：

```java
@Configuration
@ConditionalOnProperty(prefix = "cn.shareif.auth", value = "enabled", matchIfMissing = true)
public class ShareifAuthAutoConfiguration {

    @Bean
    public FilterRegistrationBean filterRegistrationBean() {
        FilterRegistrationBean bean = new FilterRegistrationBean();
        bean.setFilter(new AuthFilter());
        bean.addUrlPatterns("/*");
        return bean;
    }
}
```

设置Web拦截器，当然设置拦截器有更简单的方法，比如`@WebFilter`注解，此处仅仅是举一个`@ConditinalOnProperty`的栗子。当项目的配置文件中（比如 application.properties）定义了`cn.shareif.auth.enabled=true` 时，就会触发这个自动配置类，如果没有配置属性，默认自动触发。



```java
@Slf4j
@Configuration
@ConditionalOnResource(resources = "classpath:lib/certificate.so")
public class LibResourceAutoConfiguration {

    @Bean
    public CertificateHelper load() {
        // load from resources and return a helper bean consist of this resource.
        log.info("Oh, you have loaded the resource");
        return new CertificateHelper();
    }
}
```

当classpath中存在某个资源文件时，进行自动配置。

### Jackson

无起步依赖。

Springboot默认的Json实现是Jackson，其对应的自动配置类为`JacksonAutoConfiguration`，同时通过`JacksonHttpMessageConvertersConfiguration` 配置HttpMessageConverter实现类用于Http请求中Json到Java对象或者Java对象到Json的转换。

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
 *     public static class SomeDTOSerializer extends JsonSerializer<Customer> {
 *         // ...
 *     }
 *
 *     public static class SomeDTODeserializer extends JsonDeserializer<Customer> {
 *         // ...
 *     }
 *
 * }
 *
 */
```

JacksonHttpMessageConvertersConfiguration配置类可以提供两个bean，一个为`MappingJackson2HttpMessageConverter`，另一个为`MappingJackson2XmlHttpMessageConverter` 。前者解析媒体类型为`application/json`的数据，后者解析`application/xml`的数据。

`MappingJackson2HttpMessageConverter`实现了关键接口`GenericHttpMessageConverter` 用于将http请求转换为指定泛型类型的目标对象，将指定泛型类型的源对象转换为http响应。

总结，在Springboot启动后，就已经自动配置了一系列的bean来支持Json和Java对象的转化，如果追求性能，完全不用自己再new一个ObjectMapper甚至多个ObjectMapper，`ObjectMapper`是线程安全的，可以放心大胆的用单例模式。同时由于注解`@JsonComponent` 和bean `JsonComponentModule` ,可以非常方便的自定义某些类型的序列化与反序列化方法。所以一个项目里面有多个`ObjectMapper`是无意义的。一个项目里有一个json实现库就够了，而且Springboot完全可以针对不同的json库进行自动配置，比如gson。从微服务依赖的角度以及序列化反序列化动作一致性的角度来讲，最好不要引入多个ObjectMapper或者多个json库。

附：如何用Springboot的自己创建的`ObjectMapper`

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

当然不用静态方法的形式暴露功能，而直接在bean里autowired也是可以滴。

> References:
>
> 1. https://www.baeldung.com/spring-boot-jsoncomponent





### Mongo

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

最后，`MongoDataAutoConfiguration`会完成Spring Data for Mongo的支持，这样，在使用的时候直接注入对应的bean即可。该配置提供`MongoTemplate`, `GridFsTemplate` 用于存储小文档和大文档。

对Mongo配置项感兴趣的话，可以直接查看`MongoProperties`配置类

至此，如果没有错误抛出，就可以正常使用mongo了~



### Quartz *[to do]*

定时任务调度，起步依赖：



### Kafka

Spring提供的对Kafka客户端的封装，起步依赖：

```xml
<dependency>
	  <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
```

自动配置相关类

* `KafkaAutoConfiguration`

```java
@Configuration
@ConditionalOnClass(KafkaTemplate.class)
@EnableConfigurationProperties(KafkaProperties.class)
@Import({ KafkaAnnotationDrivenConfiguration.class, KafkaStreamsAnnotationDrivenConfiguration.class })
public class KafkaAutoConfiguration {}
```

`KafkaTemplate`由spring-kafka包引入。同时完成自动配置后，还会引入`KafkaAnnotationDrivenConfiguration`和`KafkaStreamsAnnotationDrivenConfiguration` 两个配置，前者主要用来支持spring-kafka提供的相关注解，后者和Kafka Stream相关，不做讨论，实际上起步依赖中也不会包含Kafka-Stream相关的东西，所以后者并不会生效。

自动配置提供的最重要的bean就是`KafkaTemplate`了，通过该类提供的方法，可以完成kafka消息的发送。

同时spring-kafka-test提供了内存式的kafka来进行测试，只需要引入依赖：

```xml
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka-test</artifactId>
</dependency>
```

修改配置文件：

```yaml
spring:  
  kafka:
    bootstrap-servers: ${spring.embedded.kafka.brokers}
    consumer:
      group-id: honeyroom
```



测试示例：

```java
@RunWith(SpringRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class KafkaTests {
    @ClassRule
    public static EmbeddedKafkaRule embeddedKafka = new EmbeddedKafkaRule(1, false, 5).kafkaPorts(9092);

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @Autowired
    ObjectMapper objectMapper;

    @Test
    public void testKafka() throws Exception {
        DemoMessage message = new DemoMessage();
        message.setKey("key");
        message.setValue("value");
        message.setTimestamp(DateTime.now());
        kafkaTemplate.send("test.consumer", objectMapper.writeValueAsString(message));
        Thread.sleep(1000000);
    }
}
```

通过在本地执行脚本监听，可以看到测试发出的kafka消息。

```shell
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test.consumer --from-beginning
```

kafka shell文件在[Kafka binary package](http://mirrors.tuna.tsinghua.edu.cn/apache/kafka/2.3.1/kafka_2.11-2.3.1.tgz) 的bin目录下。



### Redis

spring提供的Redis客户端的封装，起步依赖：

```xml
<dependency>
     <groupId>org.springframework.boot</groupId>
     <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

自动配置类`RedisAutoConfiguration`:

```java
@Configuration
@ConditionalOnClass(RedisOperations.class)
@EnableConfigurationProperties(RedisProperties.class)
@Import({ LettuceConnectionConfiguration.class, JedisConnectionConfiguration.class })
public class RedisAutoConfiguration {}
```

熟悉的配方，熟悉的套路，引入起步依赖后能满足`@ConditionalOnClass(RedisOperations.class)`条件，然后配置文件获取`RedisProperties.class`的配置，最后再导入`LettuceConnectionConfiguration.class` 或者 `JedisConnectionConfiguration.class`，这俩都是一个功能，就是提供`RedisTemplate`所依赖的bean，比如 `RedisConnectionFactory.class`，默认`LettuceConnectionConfiguration.class`生效。

#### 运行基于Docker的Redis

```shell
#1. 获取镜像
docker pull redis

#2. 运行镜像
docker run -p 6379:6379 -d redis:latest redis-server --requirepass "123456"

#3. 进入容器内的Redis命令行界面
docker exec -ti 1729cb4a78c4 redis-cli

#4. 进入后进行鉴权
auth 123456
```

* `-p` 映射容器端口到主机端口
* `-d` 后台运行容器并打印容器ID
* `redis:latest` docker 镜像
* `redis-server --requirepass "123456"` 容器内命令



使用由自动配置生成的`StringRedisTemplate` 。

实际上`StringRedisTemplate`是`RedisTempalte<String,String>` 的子类，因为自动配置的泛型为`<Object, Object>`，而平常的大部分操作都是`<String, String>`，所以Springboot很贴心的单独由搞了个bean专门用于key=String，value=String的template。

和其他template一样，使用上相当简单：

```java
@Slf4j
@Service
@AllArgsConstructor
public class RedisService {
    private StringRedisTemplate redisTemplate;
    private ObjectMapper objectMapper;
    private static final int DEFAULT_EXPIRE_INTERVAL = 300;
    private static final TimeUnit DEFAULT_TIME_UNIT = TimeUnit.SECONDS;

    public boolean save(String key, Object value) {
        try {
            redisTemplate.opsForValue().set(key, objectMapper.writeValueAsString(value));
            redisTemplate.expire(key, DEFAULT_EXPIRE_INTERVAL, DEFAULT_TIME_UNIT);
            return true;
        } catch (Exception e) {
            log.error("can't cache data, {}", e.getMessage());
            return false;
        }
    }
}
```

写个LLT调用一下：

```java
@RunWith(SpringRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class RedisTest {
    @Autowired
    RedisService redisService;

    @Autowired
    ObjectMapper objectMapper;

    @Test
    public void testSave() throws Exception {
        DemoMessage message = new DemoMessage();
        message.setKey("key");
        message.setValue("value");
        message.setTimestamp(DateTime.now());
        redisService.save("test", objectMapper.writeValueAsBytes(message));
    }
}
```

然后通过redis-cli查看容器中redis是否正确缓存。

