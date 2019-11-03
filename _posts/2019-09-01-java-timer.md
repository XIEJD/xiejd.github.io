---
title: Java牌定时器
date: 2019-09-01
---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [ScheduledExecutorService](#scheduledexecutorservice)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## ScheduledExecutorService

JUC包中提供的任务线程池类，可以完成定时器任务，但是使用范围比较狭窄，无法提供像Cron那种强大的定时器语义。

```java
		@Test
    public void queueTaskInMultiTread() throws Exception {
        // 核心线程池大小设置为1，则所有任务变成串行。且只有当上一个任务完成后，才会进行下一次任务。
        ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);
        Runnable printA = new ThreadTask("A");
        Runnable printB = new ThreadTask("B");
        ScheduledFuture futureA = scheduler.scheduleAtFixedRate(printA, 0, 5, TimeUnit.SECONDS);
        ScheduledFuture futureB = scheduler.scheduleAtFixedRate(printB, 0, 5, TimeUnit.SECONDS);
        Thread.sleep(10000);

        //删除futureA
        futureA.cancel(true);
        System.out.println("================");
        Thread.sleep(10000);

        //添加任务C
        Runnable printC = new ThreadTask("C");
        System.out.println("================");
        ScheduledFuture futureC = scheduler.scheduleAtFixedRate(printC, 0, 5, TimeUnit.SECONDS);
        Thread.sleep(10000);
        System.out.println("================");

        System.out.println("shutdown runnables: " + scheduler.shutdownNow());
    }
```

通过ScheduledExecutorService提供的接口，可以完成任务的执行、延迟执行、周期执行，任务的取消等操作，对于简单场景的定时任务可以胜任，但是如果碰到像“每天早上8点执行”这种定时任务，实现起来就比较丑了。
