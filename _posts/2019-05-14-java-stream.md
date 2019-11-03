---
title: '啃一啃Java中的Stream'
date: 2019-05-14
---

## 什么是流

比较偏颇的理解，流指代的就是集合类下的`stream()` api，它的作用就是将集合类型转化为`Stream<E>`接口实现的类，
官方一点说，"从支持数据处理操作的源生成的元素序列"。这个序列，实际上就是`Stream`实现类，可以调用由Stream定义的抽象方法来对数据进行批量操作，而不用像以往那样对数据集手动遍历才能进行各种操作。对于流的定义和描述，更具体的可以参考[Stream Doc](https://docs.oracle.com/javase/8/docs/api/java/util/stream/Stream.html)，或者已经尽力[翻译的博客](#)

## Stream API概览

| Method      | Description                                                  | Type                                   |
| ----------- | ------------------------------------------------------------ | -------------------------------------- |
| filter()    | 很常用的方法，将传入的方法对流中的每个数据都执行一遍         | intermediate                           |
| distinct()  | 去重，根据Object.equals(Object)来判断两个元素是否相同，并行化代价高 | stateful intermediate                  |
| skip()      | 跳过前n个元素，并行化代价高，但是如果允许跳过任意n个元素，可以改善并行化的性能 | stateful intermediate                  |
| limit()     | 截断流前n个元素，并行化代价高                                | short-circuiting stateful intermediate |
| map()       | 将传入的匿名函数应用到每一个流中的元素中                     | intermediate                           |
| flatMap()   | 将流扁平化，可以将一个元素展开成多个元素，并将这种展开操作应用到所有元素，生成新的流。 | intermediate                           |
| sorted()    | 排序，根据传入的`Comparator`                                 | stateful intermediate                  |
| anyMatch()  | 传入一个谓词`Predicate`，如果任意一个元素匹配成功，则会返回true | short-circuiting terminal              |
| noneMatch() | 传入一个谓词`Predicate`，如果所有元素都不匹配，则会返回true  | short-circuiting terminal              |
| allMatch()  | 传入一个谓词`Predicate`，如果所有元素都匹配，则会返回true    | short-circuiting terminal              |
| findAny()   | 返回一个Optional对象来描述流是否空                           | short-circuiting terminal              |
| findFirst() | 返回一个Optional来描述流的第一个元素                         | short-circuiting terminal              |
| forEach()   | 类似map，会对每个元素执行传入`Consumer`方法，不会生成新流    | terminal                               |
| collect()   | 收集元素，按传入的匿名函数判断流中的元素是否应该放入到最后结果容器中（非流） | terminal                               |
| reduce()    | 规约，将流按照传入匿名函数定义将流规约成一个值或对象         | terminal                               |
| count()     | 特殊规约操作，将流中的元素个数返回                           | terminal                               |

## 流操作

### 中间操作与终端操作（intermediate & terminal）

Java8的流操作分成了两类，一类是中间操作，一类是终端操作，这两种操作最大的区别是中间操作会产生一个新的流，而终端操作会产生其他对象或值，而非流，所以顾名思义，一个终端操作往往在调用链的末尾，而调用链的中间步骤往往都是中间操作类型的函数。

流的操作都是采用声明式的方法，大部分流的操作函数都会接受匿名函数让用户去定义各种行为。比如：

```java
List<Integer> list = Arrays.asList(1,2,3,4,5);
List<Integer> mappedList = list.stream().map(
    x -> {return x+1;}).collect(Collectors.toList());

//换一种写法
List<Integer> mappedList = list.stream().map(
    x -> {return x+1;}).collect(ArrayList::new, List::add, List::addAll);
```

匿名函数`x -> {return x+1;}`定义了一个行为：为输入元素加1返回，匿名函数传入流中`map`函数后，会被应用到每一个流中元素，并且产生一个新流（流中元素仅能被访问一次），这个新流调用`collect`函数，这个函数是个终端操作，意味着它产生的结果不能继续调用流的方法，从例子中可知，`collect`函数传入的匿名函数将流转换成了列表。

上面例子中第二种写法对`collect`的入参描述的更加清楚，一个`Supplier`提供结果存放的对象，一个往结果对象中添加元素的方法，以及一个连接（合并）两个结果存放对象的方法。`collect`还有其他更强大的用法，具体的用法将在下文描述。

### 有状态与无状态 (stateful & stateless)

Stream中的有状态无状态一般指的是声明式方法入参：行为参数或者换种说法就是匿名函数。行为参数一般用于操作Stream中的元素，有状态的行为参数意味着其产生的结果依赖于外部状态，比如一个并行流的某个行为参数依赖于一个公共的线程安全的类，不同时间行为参数获取到的状态有可能是不一样的，这就造成了结果的不一致，不同时间有不同结果。反之，就是无状态的。所以，为了避免可能的安全和性能问题，操作流的行为参数应该被设计成无状态的。

### 短路操作 （short-circuiting）

顾名思义，短路操作就是在判断一连串条件时，如果无论后续条件如何都有确定的结果时，这时候就发生了短路，直接跳过后续条件判断返回结果。比如`anyMatch()`方法，只要有一个能够判断为真，就可以直接返回结果，无需做后续判断了。

## 重要方法

### 函数式接口

在详细了解Stream的接口之前，非常有必要先了解下非常重要的函数式接口，理解了函数式接口，在流的声明式方法使用上会方便很多。

* `Function`

  ```java
  /**
   * 表示一个函数接收一个参数返回一个结果
   *
   * @param <T> 输入参数类型
   * @param <R> 输出类型
   */
  @FunctionalInterface
  public interface Function<T, R> {
  
      /**
       * 将定义的操作应用到入参上.
       */
      R apply(T t);
  
      /**
       * 该方法返回一个函数，这个函数的作用是先执行入参方法，入参方法执行的结果作为入参传递给
       * 此实现类定义的方法，最后返回结果。注意这个方法返回的是函数。
       */
      default <V> Function<V, R> compose(Function<? super V, ? extends T> before) {
          Objects.requireNonNull(before);
          return (V v) -> apply(before.apply(v));
      }
  
      /**
       * 此方法返回一个函数，这个函数的作用是先执行此实现类定义的方法，结果作为入参传递给此方
       * 法的入参方法，然后返回结果，注意该方法返回的是函数.
       */
      default <V> Function<T, V> andThen(Function<? super R, ? extends V> after) {
          Objects.requireNonNull(after);
          return (T t) -> after.apply(apply(t));
      }
  }
  ```

  `Function`接口定义的`apply`方法接受一个参数，由定义的lambda实现逻辑，另外两个默认方法`compose`和`andThen`分别返回一个lambda。这两个方法用于组合其他lambda使用，区别在于执行顺序不同。举个例子：

  ```java
  Function<Integer, Integer> plus = x -> x + 2;
  Function<Integer, Integer> times = y -> y * 2;
  ```

  定义了两个Function类，其中plus和times等号右边都实现了`apply`接口（注意实际上plus和times都是一个类实例），调用`plus.apply(1)` or `times.apply(1)`即可得到结果。调用组合函数`plus.compose(times)`，这条语句的意思实际上是先执行乘法，再执行加法，其返回的函数式实际上就是`y*2+2`。调用组合函数plus.andThen(times)，其意思实际上是先执行加法，再执行乘法，其返回的函数式实际上就是`(x+2)*2`。

* BiFunction

  ```java
  /**
   * 表示一个函数接收两个参数，产生一个结果，这实际上是Function的两元形式。
   *
   * <p>This is a <a href="package-summary.html">functional interface</a>
   * whose functional method is {@link #apply(Object, Object)}.
   *
   * @param <T> 第一个入参的类型
   * @param <U> 第二个入参的类型
   * @param <R> 返回类型
   */
  @FunctionalInterface
  public interface BiFunction<T, U, R> {
  
      /**
       * 将定义的操作应用到入参上.
       */
      R apply(T t, U u);
  
      /**
       * 此方法返回一个函数，这个函数的作用是先执行此实现类定义的方法，结果作为入参传递给此方
       * 法的入参方法，然后返回结果，注意该方法返回的是函数.
       */
      default <V> BiFunction<T, U, V> andThen(Function<? super R, ? extends V> after) {
          Objects.requireNonNull(after);
          return (T t, U u) -> after.apply(apply(t, u));
      }
  }
  ```

  注释其实讲得很清楚，Function的两元形式，没其他特殊的。举个栗子：

  ```java
  BiFunction<Integer, Double, Double> plus = (x, y) -> x + y; System.out.println(plus.apply(1,2.0));
  ```

  可以想一想，为什么BiFunction没有`compose`接口？

  一个函数可以同时返回两个对象吗？

* BinaryOperator

  ```java
  /**
   * 表示一个基于两个相同类型的操作，产生一个相同类型的结果，BiFunction的特殊情况(操作数和结果都
   * 为相同类型)
   */
  @FunctionalInterface
  public interface BinaryOperator<T> extends BiFunction<T,T,T> {
      /**
       * 返回一个选择由comparator定义大小的，最小元素选择方法。
       */
      public static <T> BinaryOperator<T> minBy(Comparator<? super T> comparator) {
          Objects.requireNonNull(comparator);
          return (a, b) -> comparator.compare(a, b) <= 0 ? a : b;
      }
  
      /**
       * 返回一个选择由comparator定义大小的，最大元素选择方法。
       */
      public static <T> BinaryOperator<T> maxBy(Comparator<? super T> comparator) {
          Objects.requireNonNull(comparator);
          return (a, b) -> comparator.compare(a, b) >= 0 ? a : b;
      }
  }
  ```

  BinaryOperator扩展了BiFunction接口，定义了两个静态方法，这两个静态方法分别返回选择最大元素的BinaryOperator和选择最小元素的BinaryOperator。举个栗子：

  ```java
  BinaryOperator<Integer> operator = (x, y) -> x + y; //匿名函数定义了apply
  BinaryOperator<Integer> maxBy = BinaryOperator.maxBy((x, y) -> y - x); // 匿名函数定义了comparator
  System.out.println(operator.apply(1,2));
  System.out.println(maxBy.apply(1,2));
  ```

  上面例子中operator和maxBy没啥关系，operator定义的是对两个入参进行加法运算，而maxBy定义的是对两个元素求较大的那个元素，而大小的比较方法，由入参Comparator定义。

### 映射（Map）

* map()

  ```java
  /**
     * Returns a stream consisting of the results of applying the given
     * function to the elements of this stream.
     *
     * 返回一个包含映射函数对每个元素执行后结果的流
     *
     * <p>This is an <a href="package-summary.html#StreamOps">intermediate
     * operation</a>.
     *
     * @param <R> The element type of the new stream
     * @param mapper a <a href="package-summary.html#NonInterference">non-interfering</a>,
     *               <a href="package-summary.html#Statelessness">stateless</a>
     *               function to apply to each element
     * @return the new stream
     */
    <R> Stream<R> map(Function<? super T, ? extends R> mapper);
  ```

  从接口定义看出，`map`函数接收一个`Function`，即接受一个入参为T或者T的父类的类型，输出为R或者R的子类型的lambda。其中R的类型即为输出流中元素的类型，T的类型为输入流中元素的类型。如本文第一个例子中lambda`x -> x+1`，输入输出类型均为`Integer`，因为输入流为`Stream<Integer>`所以lambda的输入x必须为`Integer`或者他的父类，输出流`Stream<R>`中R可以为其他任意类型。

  注释中标明入参mapper为`non-interfering`以及`stateless`的，即非干涉以及无状态的，其概念已经介绍过，可参考[Stream Doc](https://docs.oracle.com/javase/8/docs/api/java/util/stream/package-summary.html)，或蹩脚译文[Java.util.stream文档翻译](#)。简言之，就是匿名方法中不要依赖外部状态，不要对数据源进行修改或导致修改的操作。

  举个栗子：对流中数值加1

    ```java
	  List<Integer> list = Arrays.asList(1,2,3,4,5); //延用第一个栗子
	  List<Integer> mappedList = list.stream().map(x -> x+1) //这个lamdba返回的结果不会修改输入流，而是会用来生成新的输出流。
    ```

* mapToDouble()

  ```java
   	/**
     * Returns a {@code DoubleStream} consisting of the results of applying the
     * given function to the elements of this stream.
     *
     * <p>This is an <a href="package-summary.html#StreamOps">intermediate
     * operation</a>.
     *
     * @param mapper a <a href="package-summary.html#NonInterference">non-interfering</a>,
     *               <a href="package-summary.html#Statelessness">stateless</a>
     *               function to apply to each element
     * @return the new stream
     */
    DoubleStream mapToDouble(ToDoubleFunction<? super T> mapper);
  ```

  为什么单独为double类型定义一个方法？其实不止double，三种基本类型`double,int,long`都有单独的声明式方法和单独的函数式接口。

  原因很简单，因为泛型无法表示基本类型，所以`map`的泛型接口无法使用，只能单独为这三种基本类型定义新的接口，包括函数式接口，他们与普通的泛型接口不同的地方是其返回类型，泛型接口返回的是对象，而`ToDoubleFunction`返回的是基本类型`double`，`mapToDouble`返回的不是`Stream<Double>`，而是一个`DoubleStream`，这个`DoubleStream`其实和`Stream`一样继承`BaseStream`。其用法也和`Stream`几乎一样。

  举个栗子：对流中数值加1

    ```java
	  List<Double> list = Arrays.asList(Double.valueOf(1), 			 	 	   Double.valueOf(2), Double.valueOf(3),
                Double.valueOf(4), Double.valueOf(5)); 
	  DoubleStream doubleStream = list.stream().mapToDouble(x -> x+1); //这个流中的元素都是基本类型double
	  doubleStream.forEach(System.out::println); //用法和Stream一样
    ```

### 规约（Reduce）

`reduce()`有三个重载方法。

* 第一个方法

  ```java
    /**
     * This is equivalent to:
     * <pre>{@code
     *     boolean foundAny = false;
     *     T result = null;
     *     for (T element : this stream) {
     *         if (!foundAny) {
     *             foundAny = true;
     *             result = element;
     *         }
     *         else
     *             result = accumulator.apply(result, element);
     *     }
     *     return foundAny ? Optional.of(result) : Optional.empty();
     * }</pre>
     *  
     * but is not constrained to execute sequentially.
     */
    Optional<T> reduce(BinaryOperator<T> accumulator);
  ```

  理解了`reduce`方法的函数式接口入参`BinaryOperator`后，直接看官方文档的注释中的示例，就非常能明白`reduce`是怎么运作的了。解释一下接口文档中伪代码的描述：如果流为空，则返回一个Opional空对象（不是null），如果流非空，则不断的进行两元素`fold`折叠操作，第一次进行折叠时，直接将第一个元素作为上一步折叠操作的结果。以后每一次折叠操作，第一个参数为上一步的结果，第二个元素为接下来的元素。不断循环，直至得到一个单一的元素作为结果返回（由Optional包装）。

* 第二个方法

  ```java
     /**
       * This is equivalent
       * to:
       * <pre>{@code
       *     T result = identity;
       *     for (T element : this stream)
       *         result = accumulator.apply(result, element)
       *     return result;
       * }</pre>
       *
       * but is not constrained to execute sequentially.
       *
       * @apiNote Sum, min, max, average, and string连接 都是特殊的规约操作
       * 比如求和可以用如下方式定义：
       *
       * <pre>{@code
       *     Integer sum = integers.reduce(0, (a, b) -> a+b);
       * }</pre>
       *
       * 或者:
       *
       * <pre>{@code
       *     Integer sum = integers.reduce(0, Integer::sum);
       * }</pre>
  	 *
       * 用这种声明式的方法进行这种聚合，相比于直接用外循环来累加求和可能会有一点绕，但这是
       * 值得的，用声明式的方法来进行规约操作可以非常优雅的并行化，而无需额外的同步，同时极大
       * 的降低了数据竞争的风险。
       */
      T reduce(T identity, BinaryOperator<T> accumulator);
  ```

  和第一个重载方法不一样的地方在于，这个借口多了一个入参，来定义“第一次折叠操作的结果”，所以，如伪代码所示，当进行循环折叠时，因为已经有了初始值，所以不用再每次都来判断是否是第一次折叠操作了。

  栗子在注释中有，就不重复举了。需要注意的是，该接口中的泛型都是同一种，这意味着输入流中元素是什么类型，则输出的结果就是元素的类型。

* 第三个方法

  ```java
     	/**
  	 * This is equivalent to:
       * <pre>{@code
       *     U result = identity;
       *     for (T element : this stream)
       *         result = accumulator.apply(result, element)
       *     return result;
       * }</pre>
       *
       * but is not constrained to execute sequentially.
       *
       * 许多调用此方法的规约操作都可以简单地用另一种形式来表达：map + reduce（另外两个重载方法）。
       * 此接口中，accumulator 函数就像一个混合的累加和映射函数。预置第一次折叠操纵的结果identity
       * 有助于减少一些计算损耗。
       */
      <U> U reduce(U identity,
                   BiFunction<U, ? super T, U> accumulator,
                   BinaryOperator<U> combiner);
  ```

  这个接口和前两个接口的不同之处在于，其输入流的元素类型和输出的元素类型已经不一样了，输入流的元素类型是T，而输出的元素类型已经变成了U，所以它的accumulator采用的是BiFunction函数式接口，accumulator的第一个入参是上一次折叠操作的结果，初始化时第一次折叠操作的结果被设置为identity，第二个入参便是后续输入流中的元素了，然后折叠操作的结果会被当做下一次折叠操作的第一个入参，循环往复。

  至于combiner，为什么需要combiner？为什么之前两个接口没有combiner？

  其实将这三个接口放在并行化的情况下就不难理解，前两个接口并行化后，多个线程都会产生一个类型为T的结果，因为其输入元素类型和输出类型均为T，所以完全可以复用accumulator来进行合并。但是第三个接口不能复用，因为输入输出的类型并不一样，输出的是一种新的类型U，所以对于新类型U，需要定义一个如何合并的方法。特别注意的是三个接口文档中都有一句注释`but is not constrained to execute sequentially.`，表示所有操作都没有对执行顺序的要求。否则，老老实实用串行流。

### 可变规约（Collect）

Mutable Reduction Operation，可变规约`collect()`相比`reduce()`有更大的灵活性，同时也要更加注意并行化时的约束，否则性能将大打折扣。

在介绍`collect()`之前，必须先了解一下`Collector`接口。

* `Collector`

  ```java
  /**
   * Collector接口定义了四个方法来协同计算所有数据，最终将结果放入一个可变容器中。
   * 		supplier(): 提供结果容器
   * 		accumulator(): 将一个新元素放入结果容器中
   * 		combiner(): 合并两个结果容器
   * 		finisher(): 可选操作，最后将结果容器进行某种形式的转换
   *
   * Collector同时定义了一个Set来表达一些特性，比如 Characteristics.CONCURRENT，
   * 它表示的是这一组方法可以并发执行，在实现规约操作的时候可以通过Set中定义的特性来优化
   * 性能。
   *
   * 串行实现的规约操作会利用 supplier 产生一个结果容器，然后调用 accumulator 来一个一个
   * 将流元素放入结果容器中。并行实现的规约操作会将流切分，然后为每一段流创建一个结果容器，每段流
   * 中的每个元素将会用 accumulator 放入各自的结果容器中，然后最终用 combiner 将所有结果
   * 容器合并成一个。
   * 
   * 为了确保并行和串行产生相同的结果，这一组在Collector中定义的函数必须满足以下两个特性：
   * 
   * (1) Identity: 对于任何子流产生的结果，将其与一个空结果容器合并时恒等于子流产生的结果。
   *
   * (2) Associativity: 结合性，对于流中的任意元素，满足以下计算方式：
   * {
   *     A a1 = supplier.get();
   *     accumulator.accept(a1, t1);
   *     accumulator.accept(a1, t2);
   *     R r1 = finisher.apply(a1);  // 没有将结果分开
   *
   *     A a2 = supplier.get();
   *     accumulator.accept(a2, t1);
   *     A a3 = supplier.get();
   *     accumulator.accept(a3, t2);
   *     R r2 = finisher.apply(combiner.apply(a2, a3));  // 由子结果合并
   * } 
   *
   * 所有实现Collector的库必须满足以下约束：
   * 	   (1) accumulator传入的第一个参数，combiner中传入的二个参数，finisher中传入的参
   * 	   数(只有一个)，必须是上一步得到的由 supplier产生的结果容器或accumulator修改后的
   *     结果容器或combiner返回的结果容器。
   * 	   (2) 在实现时，不能对中间结果进行任何其他形式的修改，除非将其作为参数交给 accumulator,
   * 	   combiner, 或者 finisher 函数，或者将其返回给调用者。
   *     (3) 一旦中间结果或者结果交给了 combier函数或者 finisher函数，并且没有返回相同的对象，
   *     则这个中间结果或者结果并应该再被使用。
   *     (4) 一旦中间结果或者结果交给了 combier函数或者 finisher函数，这个结果不能再传递给
   *     accumulator函数。
   *     (5) 对于非并发的 collectors，由其supplier, accumulator, 或者combiner产生的结果
   *     都应该是串行的线程约束的。这样在进行并发时可以不用任何额外的同步操作。在实现规约操作时
   *     必须合理的将输入进行划分，每一部分独立处理，然后当accumulator完全结束时，将所有结果
   *     合并在一起。
   *     (6) 对于并发的 collectors，可以自由实现(不要求)规约的并发操纵，并发规约会同时从多个
   *     线程调用 accumulator来进行计算，用同一个线程安全的容器来存放结果，而不是各个线程维护
   *     一个独立的经过容器。并发规约应该在定义了 Characteristics.UNORDERED的情况下应用，或
   *     者原数据就是无序的。
   *
   * @param <T> 流元素类型
   * @param <A> 容器类型
   * @param <R> 最终规约操作结果的类型
   * 
   */
  public interface Collector<T, A, R> {
      /**
    	 * 调用这个函数能生产一个新的可变容器
       */
      Supplier<A> supplier();
  
      /**
       * 调用这个函数能将一个流元素折叠进结果容器
       */
      BiConsumer<A, T> accumulator();
  
      /**
       * 合并两个中间结果
       */
      BinaryOperator<A> combiner();
  
      /**
       * 将容器结果转换为最终需要的结果
       */
      Function<A, R> finisher();
  
      /**
       * 返回一个包含特性的Set集合
       */
      Set<Characteristics> characteristics();
  
      enum Characteristics {
          //并发性
          CONCURRENT,
  
          //无序性
          UNORDERED,
  
          //最终结果的转换可以省略，A类型转换成R类型肯定成功
          IDENTITY_FINISH
      }
  }
  ```

  `Collector`的接口文档已经很好的描述了实际上其可以由一组功能各异的匿名函数来定义一个组合行为，其中包括一个`Supplier`提供结果容器，一个`BiConsumer`来将流元素经过处理后放入结果容器中，一个`BinaryOperator`来合并中间结果，一个`finisher`来进行最后结果转换。可以通过`Collector.of()`方法来获取一个Collector实例。

  `Collectors`是一个静态方法工厂，其中实现了许多通用的`Collector`，比如`maxBy, groupingBy,summingInt`等等。

`collect()`有两个重载方法。

* 第一个方法

  ```java
     /**
       * The following will accumulate strings into an ArrayList:
       * <pre>{@code
       *     List<String> asList = stringStream.collect(Collectors.toList());
       * }</pre>
       *
       * <p>The following will classify {@code Person} objects by city:
       * <pre>{@code
       *     Map<String, List<Person>> peopleByCity
       *         = personStream.collect(Collectors.groupingBy(Person::getCity));
       * }</pre>
       *
       * <p>The following will classify {@code Person} objects by state and city,
       * cascading two {@code Collector}s together:
       * <pre>{@code
       *     Map<String, Map<String, List<Person>>> peopleByStateAndCity
       *         = personStream.collect(Collectors.groupingBy(Person::getState,
       *                                Collectors.groupingBy(Person::getCity)));
       * }</pre>
       *
       * @param <R> 结果类型
       * @param <A> 中间结果计算类型
       */
      <R, A> R collect(Collector<? super T, A, R> collector);
  ```

  将文档中的栗子单独拉出来看（自己举的栗子没文档好）：

  ```java
  List<String> asList = stringStream.collect(Collectors.toList()); //栗子1
  ```

  栗子1是`collect`方法的简单实用，将一个`Stream<String>`流转换成了一个`List<String>`，实际上`Collectors.toList`的定义如下：

  ```java
   public static <T>
      Collector<T, ?, List<T>> toList() {
          return new CollectorImpl<>((Supplier<List<T>>) ArrayList::new, List::add,
                                     (left, right) -> { left.addAll(right); return left; },
                                     CH_ID);
      }
  ```

  可以非常清楚的看到，supplier = `ArrayList::new`，accumulator = `List::add`，combiner = `(x, y)->{x.addAll(y); return x;}`。

  文档中另一个分类的栗子：

  ```java
  Map<String, List<Person>> peopleByCity
      = personStream.collect(Collectors.groupingBy(Person::getCity)); //栗子2
  ```

  栗子2使用了`Collecotrs.groupingBy`静态工厂来生成`Collector`，这个方法将会根据`Person::getCity`方法产生的值最为键来聚合拥有相同键的元素为一个List。看一个更复杂一点的分组栗子：

  ```java
  Map<String, Map<String, List<Person>>> peopleByStateAndCity
        = personStream.collect(Collectors.groupingBy(Person::getState,
                               Collectors.groupingBy(Person::getCity))); //栗子3
  ```

  这个方法能实现二级分组，即在用`Person::getState`聚合同类元素后，在同类元素中继续用`Person::getCity`进行聚合。所以，当大家看到这种用法的时候，是不是会想：\*\*！这个理论上可以无限级分组啊！太\*\*厉害了！，而且不仅仅是分组，还能对分完组的同类元素继续规约，比如：

  ```java
  Map<String, Map<String, List<Person>>> peopleByStateAndCity
        = personStream.collect(Collectors.groupingBy(Person::getState,
                               Collectors.summingInt(Person::getAge)); //栗子3改
  ```

  Awesome！

* 第二个方法

  ```java
   /**
       * This produces a result equivalent to:
       * <pre>{@code
       *     R result = supplier.get();
       *     for (T element : this stream)
       *         accumulator.accept(result, element);
       *     return result;
       * }</pre>
       */
      <R> R collect(Supplier<R> supplier,
                    BiConsumer<R, ? super T> accumulator,
                    BiConsumer<R, R> combiner);
  ```

  了解了`Collecotr`的作用后，其实看这个方法的入参就非常简单了，只是最后一个combiner使用的是`BiConsumer<R, R>`接口而不是`BinaryOperator<R>`其实这俩接口的不同之处就在于一个无返回值，一个有返回值，其实作用是一样的。

## REFERENCES

> * 《Java8 实战》
> * [Stream API Doc](https://docs.oracle.com/javase/8/docs/api/java/util/stream/Stream.html)
> * [使用compose和andThen组合函数](http://www.importnew.com/17209.html)
