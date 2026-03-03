# Convention-Based Dependency Injection

Guide for implementing convention-based handler discovery in Clean Architecture CQRS projects.

## Why Convention-Based DI?

**Problem**: API layer cannot reference Application layer directly (Clean Architecture rule), yet endpoints need to invoke handlers.

**Solution**: Infrastructure layer discovers handlers by naming convention and registers them in DI container. API injects interfaces.

## Benefits

- **Explicit interfaces**: `ICommandHandler<>` / `IQueryHandler<>` are clear contracts
- **Type-safe**: Compile-time verification of handler signatures
- **Testable**: Easy to mock handlers in tests
- **Maintainable**: Convention enforced by NetArchTest tests

## Implementation

### 1. Define Handler Interfaces (Application Layer)

```csharp
// Application/Shared/ICommandHandler.cs
namespace MyProject.Application.Shared;

public interface ICommandHandler<in TCommand>
{
    Task HandleAsync(TCommand command, CancellationToken cancellationToken = default);
}

public interface ICommandHandler<in TCommand, TResult>
{
    Task<TResult> HandleAsync(TCommand command, CancellationToken cancellationToken = default);
}

public interface IQueryHandler<in TQuery, TResult>
{
    Task<TResult> HandleAsync(TQuery query, CancellationToken cancellationToken = default);
}
```

### 2. Define Bus Interfaces (Application Layer)

Sender interfaces abstract handler dispatch. API endpoints inject senders instead of individual handlers.

```csharp
// Application/Shared/ICommandBus.cs
namespace MyProject.Application.Shared;

public interface ICommandBus
{
    Task PublishAsync<TCommand>(TCommand command, CancellationToken cancellationToken = default);
    Task<TResult> PublishAsync<TCommand, TResult>(TCommand command, CancellationToken cancellationToken = default);
}

// Application/Shared/IQueryBus.cs
namespace MyProject.Application.Shared;

public interface IQueryBus
{
    Task<TResult> SendAsync<TQuery, TResult>(TQuery query, CancellationToken cancellationToken = default);
}
```

### 3. Implement Handlers (Application Layer)

**Naming Convention**: Handler class must end with `CommandHandler` or `QueryHandler` suffix.

```csharp
// Application/Orders/Commands/PlaceOrder/PlaceOrderCommandHandler.cs
namespace MyProject.Application.Orders.Commands.PlaceOrder;

public sealed class PlaceOrderCommandHandler : ICommandHandler<PlaceOrderCommand, OrderId>
{
    private readonly IOrderRepository _orderRepository;
    
    public PlaceOrderCommandHandler(IOrderRepository orderRepository)
    {
        _orderRepository = orderRepository;
    }
    
    public async Task<OrderId> HandleAsync(
        PlaceOrderCommand command,
        CancellationToken cancellationToken = default)
    {
        var order = Order.Create(command.OrderId, command.CustomerId);
        // ... business logic
        await _orderRepository.AddAsync(order, cancellationToken);
        return order.Id;
    }
}
```

### 4. Convention-Based Registration (Infrastructure Layer)

```csharp
// Infrastructure/DependencyInjection.cs
namespace MyProject.Infrastructure;

using MyProject.Application;
using MyProject.Application.Shared;
using MyProject.Infrastructure.CQRS;
using Microsoft.Extensions.DependencyInjection;

public static class DependencyInjection
{
    /// <summary>
    /// Registers a single command or query handler.
    /// </summary>
    public static IServiceCollection AddHandler<THandler>(this IServiceCollection services)
        where THandler : class
    {
        var handlerType = typeof(THandler);
        var handlerInterfaces = handlerType.GetInterfaces()
            .Where(i => i.IsGenericType && 
                   (i.GetGenericTypeDefinition() == typeof(ICommandHandler<>) ||
                    i.GetGenericTypeDefinition() == typeof(ICommandHandler<,>) ||
                    i.GetGenericTypeDefinition() == typeof(IQueryHandler<,>)));

        foreach (var @interface in handlerInterfaces)
            services.AddScoped(@interface, handlerType);

        return services;
    }

    /// <summary>
    /// Registers all command and query handlers from the Application assembly.
    /// </summary>
    public static IServiceCollection AddApplicationHandlers(
        this IServiceCollection services)
    {
        var applicationAssembly = typeof(IApplicationMarker).Assembly;
        
        var allTypes = applicationAssembly.GetTypes()
            .Where(t => !t.IsInterface && !t.IsAbstract);
            
        foreach (var type in allTypes)
        {
            var handlerInterfaces = type.GetInterfaces()
                .Where(i => i.IsGenericType && 
                       (i.GetGenericTypeDefinition() == typeof(ICommandHandler<>) ||
                        i.GetGenericTypeDefinition() == typeof(ICommandHandler<,>) ||
                        i.GetGenericTypeDefinition() == typeof(IQueryHandler<,>)));
                        
            foreach (var @interface in handlerInterfaces)
                services.AddScoped(@interface, type);
        }
        
        return services;
    }

    /// <summary>
    /// Registers Infrastructure services (CQRS buses, repositories, external services).
    /// Does NOT register handlers — use AddHandler&lt;T&gt;() or AddApplicationHandlers() separately.
    /// </summary>
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services)
    {
        services.AddScoped<ICommandBus, CommandBus>();
        services.AddScoped<IQueryBus, QueryBus>();
        
        return services;
    }
}
```

### 5. Sender Implementations (Infrastructure Layer)

Senders resolve handlers from DI and dispatch to them:

```csharp
// Infrastructure/CQRS/CommandBus.cs
namespace MyProject.Infrastructure.CQRS;

public sealed class CommandBus : ICommandBus
{
    private readonly IServiceProvider _serviceProvider;

    public CommandBus(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public async Task PublishAsync<TCommand>(TCommand command, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(command);
        var handler = _serviceProvider.GetRequiredService<ICommandHandler<TCommand>>();
        await handler.HandleAsync(command, cancellationToken);
    }

    public async Task<TResult> PublishAsync<TCommand, TResult>(TCommand command, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(command);
        var handler = _serviceProvider.GetRequiredService<ICommandHandler<TCommand, TResult>>();
        return await handler.HandleAsync(command, cancellationToken);
    }
}

// Infrastructure/CQRS/QueryBus.cs
namespace MyProject.Infrastructure.CQRS;

public sealed class QueryBus : IQueryBus
{
    private readonly IServiceProvider _serviceProvider;

    public QueryBus(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public async Task<TResult> SendAsync<TQuery, TResult>(TQuery query, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(query);
        var handler = _serviceProvider.GetRequiredService<IQueryHandler<TQuery, TResult>>();
        return await handler.HandleAsync(query, cancellationToken);
    }
}
```

### 6. Configure DI (Program.cs)

```csharp
using MyProject.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Register CQRS buses (ICommandBus, IQueryBus)
builder.Services.AddInfrastructure();

// Register handlers — choose one:
// Option A: Bulk convention-based registration (scans Application assembly)
builder.Services.AddApplicationHandlers();
// Option B: Explicit single handler registration
builder.Services.AddHandler<PlaceOrderCommandHandler>();

var app = builder.Build();
```

### 7. Inject Handlers in API Endpoints (API Layer)

**Critical**: API injects `ICommandHandler<>` / `IQueryHandler<>` interfaces (NOT concrete classes).

```csharp
// API/Orders/OrdersEndpoints.cs
namespace MyProject.Api.Orders;

public static class OrdersEndpoints
{
    public static void MapOrdersEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/orders").WithTags("Orders");
        
        group.MapPost("/", PlaceOrder);
        group.MapGet("/{orderId:guid}", GetOrder);
    }
    
    private static async Task<IResult> PlaceOrder(
        PlaceOrderCommand command,
        ICommandHandler<PlaceOrderCommand, OrderId> handler, // ← Injected by DI
        CancellationToken cancellationToken)
    {
        var orderId = await handler.HandleAsync(command, cancellationToken);
        return Results.Created($"/api/orders/{orderId.Value}", orderId);
    }
    
    private static async Task<IResult> GetOrder(
        Guid orderId,
        IQueryHandler<GetOrderQuery, OrderViewModel> handler, // ← Injected by DI
        CancellationToken cancellationToken)
    {
        var query = new GetOrderQuery(new OrderId(orderId));
        var result = await handler.HandleAsync(query, cancellationToken);
        return Results.Ok(result);
    }
}
```

## Convention Rules

### MUST Follow

1. **Command handlers**: Class name MUST end with `CommandHandler`
2. **Query handlers**: Class name MUST end with `QueryHandler`
3. **Implement interface**: Handler MUST implement `ICommandHandler<>` or `IQueryHandler<>`
4. **Public class**: Handler class MUST be public (DI registration requires public types)

### Enforced by NetArchTest

Naming conventions are validated by architecture tests using `NetArchTest.Rules`. See [netarchtest-rules reference](netarchtest-rules.md).

## Testing

### Unit Tests (Mock Infrastructure)

```csharp
// UnitTests/Application/Orders/PlaceOrderCommandHandlerTests.cs
[Fact]
public async Task WhenPlacingOrder_ShouldCreateOrder()
{
    // Arrange - Mock Infrastructure
    var orderRepository = A.Fake<IOrderRepository>();
    var handler = new PlaceOrderCommandHandler(orderRepository);
    
    var command = new PlaceOrderCommand(/*...*/);
    
    // Act - Handler is REAL (not mocked)
    var orderId = await handler.HandleAsync(command);
    
    // Assert - Verify Infrastructure calls
    A.CallTo(() => orderRepository.AddAsync(
        A<Order>.That.Matches(o => o.Id == command.OrderId),
        A<CancellationToken>._
    )).MustHaveHappenedOnceExactly();
}
```

### Integration Tests (Test DI Resolution)

```csharp
// IntegrationTests/Api/Orders/PlaceOrderEndpointTests.cs
[Fact]
public async Task PlaceOrder_ShouldResolveHandlerFromDI()
{
    // Arrange
    var factory = new WebApplicationFactory<Program>();
    var client = factory.CreateClient();
    
    var command = new PlaceOrderCommand(/*...*/);
    
    // Act - DI resolves ICommandHandler<PlaceOrderCommand, OrderId>
    var response = await client.PostAsJsonAsync("/api/orders", command);
    
    // Assert
    response.StatusCode.Should().Be(HttpStatusCode.Created);
}
```

## Related

- **Clean Architecture**: [clean-architecture-dotnet skill](../SKILL.md)
- **Testing**: See the `application-layer-testing` skill for testing patterns
