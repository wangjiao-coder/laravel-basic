# 起源

## 1.0
- 1.0专注于项目的快速搭建。
- 1.0专注于组件集成。
- 1.0更像是一个对于laravel和composer的系统入门介绍。

## 环境变化
- 琐碎小项目的数量有所减少。
- 我们需要应对大中型项目，而这些项目需要多人合作。

## 2.0演进
- 2.0会更关心系统的架构，而不是快速启动。
- 2.0会包含解决具体问题的示例，事实证明这是统一风格的最好方式。
- laravel中解决一个问题可以有多个方案。但是为了项目的健康，我们需要做一些减法，只用标准手段处理问题。

# 新规则
- 对于业务逻辑，只使用依赖注入。
- 对于cache, storage, db, route等框架内置门面，可以使用门面。
- 不要在Http层以外使用Http相关的门面和Helper，如request(),response(),cookie(),session()。不要在DB层以外使用DB。
- 除非有特别合理的理由，不使用闭包处理请求和事件。单独创建class。
- 优化性能，不需要Session则不启用。
- 优化性能，路由中不使用闭包，除config文件外不使用env()。

> 最后一条规则是为了使用php artisan route:cache和php artisan config:cache。

# 系统架构
- 从一开始就应该考虑多人合作的大型项目。分模块，分层次。

| 系统结构 | 订单模块 | 财务模块 | 用户模块 |
|---|---|---|---|
| 通讯层 | Controllers | Controllers | Controllers |
| 服务层 | Services | Services | Services |
| 数据层 | Model | Model | Model |

## 横向来看
- Requests, Middleware，Controller, Resources都属于通讯层。通讯层处理所有HTTP层的内容，比如CORS、请求参数提取、返回值拼装，请求链路异常处理等。

> Request对象不能传入下一层。

- Services属于业务逻辑。Services大多数时候是由Controller来调用的，也可以被Events、Jobs等调用。使用Services时必须将Services注入到对应的类中。Services和Services之间也可以互相注入，形成依赖关系。这一层中可以根据需要使用一些常见的设计模式（如装饰器模式）。

> Services层中不应直接操作数据库。

- Models和Repositories属于数据层。Repositories一般用于处理关于集合的操作。Model则是具体实例的操作。

> 为了充分利用Model中的事件和关系，应该尽可能的使用Model提供的方法，而不是通过SQL直接操作。

- 每一层都可能抛出Event，甚至还有的Event在框架中（如Service Container中），不属于任何一层。但是Event Listener都属于服务层。

## 纵向来看
- 每一个模块应当保持独立。
- 互相之间不访问对方的Model。
- Controllers在一般情况下也是完全隔离的。
- 在少数情况下，**读操作**可以访问对方的特定Service。如订单模块获取用户名称。如果频繁访问对方的services，则应考虑模块合二为一。
- 模块之间**写操作**，最常见的方式是通过事件。如财务模块发现用户钱已经消耗光后抛出事件，用户模块监听该事件并向用户发出通知。

> 在上述例子中，事件的命名应该是deposit depleted, 而不是notify user. 即，事件只属于当前触发模块，不应了解监听模块要做什么。

> 尽量减少自定义事件，监听框架中的标准事件(model created, updated)可以对事件的时机和内容有更准确的预期。

## 每个格子来看
- 每个Class中有好多个方法。所以设计架构时一定会面临一个问题：哪些方法适合放到同一个Class中？
  - 对于Controller，我们按views来分组。如DashboardController，OrderListController，UserProfileController等。 
  - 对于Model，我们按照Mysql表来分组。如UserModel, OrderModel, AccountModel等。
  - 对于Service该怎么分组？
    - 按照View分组：Service变得臃肿，随着需求变化边界会模糊，没有清晰的Interface, 不符合接口隔离原则。
    - 按照Model分组：稍微复杂的业务，都会涉及到Model之间的协同变化，Service不可能按照Model分组。
    - 按模块分组：不符合单一职责的严责，所有设计模式也全都作废。
    - **正解**: 按照最小逻辑单元分组。什么是最小逻辑单元？就是产品的脑图的最小分支。
![alt text](https://www.biggerplate.com/mapImages/xl/r4DyPCJE_Mind-Mapping-functionality-in-XMind-8-mind-map.png "脑图")
    - 这样分组会产生很多只有一个方法的Service，这是OK的。
    - 我们可以将最小颗粒度的Service组合成中层Service，再把中层Service组合成高级Service。
    - 跨模块访问时，应该访问对方的根Service。[快速生成根服务](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Order/Services/OrderServiceRegistry.php "link") [注册根服务](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Order/Providers/OrderServiceProvider.php#L40) [访问根服务](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Finance/Http/Controllers/FinanceController.php#L19)

# FAQ
- 为什么模块之间鼓励使用事件交换信息？
  - 答：事件可以实现控制的反转。简单来说，事件使得我们可以把每个模块的逻辑写在各自的模块里，哪怕触发器在其他模块中。
- 有什么好用的设计模式？
  - 答：《设计模式》这本书里都有。我也写了一些例子。
  - [装饰器模式](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Order/Services/OrderStatus/LoggedOrderStatusService.php "装饰器模式")。更新：[更好的写法](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/1446b72ac981e89ef096cf3b9c996590888bf35c/Modules/Order/Services/OrderStatus/AuthOrderStatusService.php "装饰器模式")。
  - [状态模式1](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Order/Services/OrderStatus/OpenOrderStatus.php "状态模式1"), [状态模式2](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Order/Services/OrderStatus/CloseOrderStatus.php "状态模式2"), [状态模式3](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Order/Services/OrderStatus/PauseOrderStatus.php "状态模式3"), [状态模式4](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Order/Services/OrderStatus/OrderStatusService.php "状态模式4")。
  - [策略模式1](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Order/Services/AudiencePredition/AudiencePreditionStrategy.php "策略模式1")，[策略模式2](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Order/Services/AudiencePredition/MathAudiencePreditionStrategy.php "策略模式2")，[策略模式3](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Order/Services/AudiencePredition/ApiAudiencePreditionStrategy.php "策略模式3")，[策略模式4](https://glab.tagtic.cn/AdsGroup/donews-php-base2/blob/example/Modules/Order/Services/AudiencePredition/AudiencePreditionService.php "策略模式4")。
  - 欢迎添加。

- 我该使用哪种设计模式？
  - 答：如果不确定就不用。

- 如何减少代码冗余？
  - 组合：当我们的Service拆分到最小逻辑单元的时候，我们可以用组合的方式减少代码冗余。PHP里的Trait也是实现组合的一种方式。
  - 继承：通过继承重载不同的方法，再通过Service Container注入。继承的好处是可以实现里氏替换。
  - 组合优先于继承。
  - 其他：要具体问题具体分析。总体而言，要把能重用的部分拆分出去。

- 排期管理中的痛点怎么解决？
  - 答：排期的问题在于我们使用的模型（时间点）对问题（时间段）的表达能力不够。[这个库可以完美解决。](https://period.thephpleague.com/)







