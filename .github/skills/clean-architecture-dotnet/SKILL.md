---
name: clean-architecture-dotnet
description: Use when setting up Clean Architecture in .NET with DDD, CQRS handlers, and compile-time architecture validation
---

# Clean Architecture CQRS

## Overview

Complete guide for implementing Clean Architecture with Domain-Driven Design and CQRS pattern in C# using convention-based handler discovery.

**Core principle:** Enforce layer independence through dependency inversion, validate architecture at compile-time with NetArchTest, and discover handlers by naming convention.

## When to Use

**Use when:**
- Starting new .NET project requiring separation of concerns and testability
- Team wants compile-time architecture validation (NetArchTest tests)
- Want explicit handler interfaces with convention-based registration
- Need CQRS pattern with explicit handler interfaces
- Setting up Clean Architecture layers (Domain, Application, Infrastructure, API)
- Domain model must have zero external dependencies (pure business logic)

**Don't use when:**
- Simple CRUD prototypes without complex business logic (overkill)
- Team unfamiliar with Clean Architecture/DDD patterns (training needed first)
- Rapid prototyping where architecture validation slows iteration

## Core Pattern

**Convention-based CQRS handlers** with explicit interfaces and auto-discovery:

```csharp
// 1. Define explicit handler interfaces (Application/Shared/)
public interface ICommandHandler<in TCommand, TResult>
{
    Task<TResult> HandleAsync(TCommand command, CancellationToken cancellationToken = default);
}

public interface IQueryHandler<in TQuery, TResult>
{
    Task<TResult> HandleAsync(TQuery query, CancellationToken cancellationToken = default);
}

// 2. Implement handler following naming convention
public sealed class PlaceOrderCommandHandler : ICommandHandler<PlaceOrderCommand, OrderId>
{
    public async Task<OrderId> HandleAsync(PlaceOrderCommand command, CancellationToken ct = default)
    {
        // Handler logic
    }
}

// 3. Auto-registered via Infrastructure DI scanning (zero manual registration)
// Infrastructure scans for *CommandHandler and *QueryHandler classes

// 4. API injects handler interface directly (no Application assembly reference)
group.MapPost("/", async (
    PlaceOrderCommand command,
    ICommandHandler<PlaceOrderCommand, OrderId> handler,  // ← Resolved by DI
    CancellationToken ct) =>
{
    var orderId = await handler.HandleAsync(command, ct);
    return Results.Created($"/api/orders/{orderId.Value}", orderId);
});
```

**Key benefits:** Explicit contracts, zero external dependencies, convention-based discovery, compile-time safety.

## Core Principles

Based on:
- **Robert C. Martin** (Clean Architecture - dependency inversion, independent layers)
- **Eric Evans** (Domain-Driven Design - domain isolation, ubiquitous language)
- **Martin Fowler** (Patterns of Enterprise Application Architecture - layering, CQRS)
- **Vaughn Vernon** (Implementing DDD - aggregates, bounded contexts)

### The Four Layers

```
┌─────────────────────────────────────┐
│         API Layer                   │  ← Entry point, HTTP endpoints
│  (ASP.NET Core, Controllers)        │  ← Does NOT reference Application
└──────────────┬──────────────────────┘
               │
        ┌──────▼──────────────────────┐
        │  Infrastructure Layer       │  ← Implements interfaces
        │  (Repositories, Services)   │  ← References Application + Domain
        │  ← Dependency Injection      │  ← Discovers handlers by convention
        └──────┬──────────────────────┘
               │
        ┌──────▼──────────────────────┐
        │   Application Layer         │  ← Use cases, orchestration
        │   (CQRS Handlers)            │  ← References Domain only
        └──────┬──────────────────────┘
               │
        ┌──────▼──────────────────────┐
        │    Domain Layer             │  ← Business logic, aggregates
        │    (Entities, Value Objects) │  ← No external dependencies
        └─────────────────────────────┘
```

### Dependency Rules

1. **Domain**: ZERO external dependencies (not even System.Data, EF Core)
2. **Application**: References Domain only
3. **Infrastructure**: References Application + Domain (implements interfaces)
4. **API**: References Infrastructure + Domain (NOT Application)

**Critical**: API discovers handlers through Infrastructure's DI container, not direct references.

---

## CQRS Pattern

### Handler Interfaces

```csharp
// Application/Shared/ICommandHandler.cs

/// <summary>
/// Handler for commands that don't return a result (void operations).
/// </summary>
public interface ICommandHandler<in TCommand>
{
    Task HandleAsync(TCommand command, CancellationToken cancellationToken = default);
}

/// <summary>
/// Handler for commands that return a result.
/// </summary>
public interface ICommandHandler<in TCommand, TResult>
{
    Task<TResult> HandleAsync(TCommand command, CancellationToken cancellationToken = default);
}

/// <summary>
/// Handler for queries (read operations).
/// </summary>
public interface IQueryHandler<in TQuery, TResult>
{
    Task<TResult> HandleAsync(TQuery query, CancellationToken cancellationToken = default);
}
```

### Bus Interfaces

Buses abstract handler dispatch. Defined in Application, implemented in Infrastructure.

```csharp
// Application/Shared/ICommandBus.cs
public interface ICommandBus
{
    Task PublishAsync<TCommand>(TCommand command, CancellationToken cancellationToken = default);
    Task<TResult> PublishAsync<TCommand, TResult>(TCommand command, CancellationToken cancellationToken = default);
}

// Application/Shared/IQueryBus.cs
public interface IQueryBus
{
    Task<TResult> SendAsync<TQuery, TResult>(TQuery query, CancellationToken cancellationToken = default);
}
```

Implementations in `Infrastructure/CQRS/` resolve handlers from the DI container via `IServiceProvider.GetRequiredService<>()`.

### Convention-Based Discovery

Infrastructure registers handlers automatically by naming convention:

```csharp
// Infrastructure/DependencyInjection.cs
public static class DependencyInjection
{
    /// <summary>
    /// Registers a single command or query handler explicitly.
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
    /// Registers Infrastructure services (CQRS buses only).
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

### Naming Conventions

**MUST follow these conventions** for auto-discovery:

- **Commands**: `[Action]Command.cs` → Handler: `[Action]CommandHandler.cs`
- **Queries**: `[Action]Query.cs` → Handler: `[Action]QueryHandler.cs`
- **ViewModels**: `[Entity]ViewModel.cs` (for frontend DTOs)

Examples:
- `PlaceOrderCommand` → `PlaceOrderCommandHandler`
- `GetOrderQuery` → `GetOrderQueryHandler`
- `OrderViewModel` (NOT `OrderDto`)

---

## Implementation Patterns

### Command (Write Operation)

```csharp
// Application/Features/PlaceOrder/PlaceOrderCommand.cs
public sealed record PlaceOrderCommand(
    OrderId OrderId,
    CustomerId CustomerId,
    List<OrderLineDto> OrderLines,
    Address ShippingAddress
);

public sealed record OrderLineDto(
    ProductId ProductId,
    string ProductName,
    int Quantity,
    decimal UnitPrice
);

// Application/Features/PlaceOrder/PlaceOrderCommandHandler.cs
public sealed class PlaceOrderCommandHandler : ICommandHandler<PlaceOrderCommand, OrderId>
{
    private readonly IOrderRepository _orderRepository;
    private readonly IInventoryService _inventoryService;
    
    public PlaceOrderCommandHandler(
        IOrderRepository orderRepository,
        IInventoryService inventoryService)
    {
        _orderRepository = orderRepository;
        _inventoryService = inventoryService;
    }
    
    public async Task<OrderId> HandleAsync(
        PlaceOrderCommand command,
        CancellationToken cancellationToken = default)
    {
        // 1. Create Domain aggregate (business logic in Domain)
        var order = Order.Create(
            command.OrderId,
            command.CustomerId,
            command.ShippingAddress);
        
        // 2. Apply business operations through Domain methods
        foreach (var line in command.OrderLines)
        {
            order.RegisterOrderItem(
                line.ProductId,
                line.ProductName,
                line.Quantity,
                line.UnitPrice);
        }
        
        order.Confirm();
        
        // 3. Orchestrate Infrastructure calls
        await _inventoryService.ReserveItemsAsync(order.OrderLines, cancellationToken);
        await _orderRepository.AddAsync(order, cancellationToken);
        
        return order.Id;
    }
}
```

### Query (Read Operation)

```csharp
// Application/Features/GetOrder/GetOrderQuery.cs
public sealed record GetOrderQuery(OrderId OrderId);

// Application/Features/GetOrder/OrderViewModel.cs
public sealed record OrderViewModel(
    Guid OrderId,
    Guid CustomerId,
    string Status,
    List<OrderLineViewModel> OrderLines,
    AddressViewModel ShippingAddress,
    DateTime CreatedAt
);

public sealed record OrderLineViewModel(
    string ProductName,
    int Quantity,
    decimal UnitPrice,
    decimal Total
);

public sealed record AddressViewModel(
    string Street,
    string City,
    string Country
);

// Application/Features/GetOrder/GetOrderQueryHandler.cs
public sealed class GetOrderQueryHandler : IQueryHandler<GetOrderQuery, OrderViewModel>
{
    private readonly IOrderRepository _orderRepository;
    
    public GetOrderQueryHandler(IOrderRepository orderRepository)
    {
        _orderRepository = orderRepository;
    }
    
    public async Task<OrderViewModel> HandleAsync(
        GetOrderQuery query,
        CancellationToken cancellationToken = default)
    {
        var order = await _orderRepository.GetByIdAsync(query.OrderId, cancellationToken);
        
        if (order is null)
            throw new OrderNotFoundException(query.OrderId);
        
        // Map Domain to ViewModel
        return new OrderViewModel(
            order.Id.Value,
            order.CustomerId.Value,
            order.Status.ToString(),
            order.OrderLines.Select(ol => new OrderLineViewModel(
                ol.ProductName,
                ol.Quantity,
                ol.UnitPrice,
                ol.Total
            )).ToList(),
            new AddressViewModel(
                order.ShippingAddress.Street,
                order.ShippingAddress.City,
                order.ShippingAddress.Country
            ),
            order.CreatedAt
        );
    }
}
```

### API Endpoint (No Application Reference)

```csharp
// API/Orders/OrdersEndpoints.cs
public static class OrdersEndpoints
{
    public static void MapOrdersEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/orders").WithTags("Orders");
        
        // Command endpoint
        group.MapPost("/", PlaceOrder)
            .WithName("PlaceOrder");
            
        // Query endpoint
        group.MapGet("/{orderId:guid}", GetOrder)
            .WithName("GetOrder");
    }
    
    private static async Task<IResult> PlaceOrder(
        PlaceOrderCommand command,
        ICommandHandler<PlaceOrderCommand, OrderId> handler,
        CancellationToken cancellationToken)
    {
        var orderId = await handler.HandleAsync(command, cancellationToken);
        return Results.Created($"/api/orders/{orderId.Value}", orderId);
    }
    
    private static async Task<IResult> GetOrder(
        Guid orderId,
        IQueryHandler<GetOrderQuery, OrderViewModel> handler,
        CancellationToken cancellationToken)
    {
        var query = new GetOrderQuery(new OrderId(orderId));
        var result = await handler.HandleAsync(query, cancellationToken);
        return Results.Ok(result);
    }
}
```

**Key**: API injects `ICommandHandler<>` and `IQueryHandler<>` directly. Infrastructure DI resolved them via convention.

---

## Marker Interfaces

Use marker interfaces to discover assemblies for DI and NetArchTest:

```csharp
// Domain/_Markers/IDomainMarker.cs
namespace Ordering.Domain;

/// <summary>
/// Marker interface to identify the Domain assembly.
/// Use: typeof(IDomainMarker).Assembly
/// </summary>
public interface IDomainMarker { }

// Application/_Markers/IApplicationMarker.cs
namespace Ordering.Application;

/// <summary>
/// Marker interface to identify the Application assembly.
/// Use: typeof(IApplicationMarker).Assembly
/// </summary>
public interface IApplicationMarker { }
```

Benefits:
- **Assembly discovery**: `typeof(IApplicationMarker).Assembly.GetTypes()`
- **NetArchTest tests**: Validate layer dependencies
- **DI registration**: Convention-based scanning

---

## Architecture Validation with NetArchTest

### Test Structure

```csharp
// ArchitectureTests/ArchitectureTests.cs
using System.Reflection;
using NetArchTest.Rules;
using Ordering.Api;
using Ordering.Application;
using Ordering.Domain;
using Ordering.Infrastructure;
using Xunit;

namespace Ordering.IntegrationTests;

public sealed class ArchitectureTests
{
    private const string DomainNamespace = "Ordering.Domain";
    private const string ApplicationNamespace = "Ordering.Application";
    private const string InfrastructureNamespace = "Ordering.Infrastructure";
    private const string ApiNamespace = "Ordering.Api";

    private static readonly Assembly DomainAssembly = typeof(IDomainMarker).Assembly;
    private static readonly Assembly ApplicationAssembly = typeof(IApplicationMarker).Assembly;
    private static readonly Assembly InfrastructureAssembly = typeof(IInfrastructureMarker).Assembly;
    private static readonly Assembly ApiAssembly = typeof(IApiMarker).Assembly;

    [Fact]
    public void Domain_Classes_Should_Be_Sealed()
    {
       var result = Types
            .InAssembly(DomainAssembly)
            .That().AreClasses()
            .Should().BeSealed()
            .GetResult();
 
       Assert.True(result.IsSuccessful, "All Domain classes must be sealed.");
    }

    /// <summary>
    /// Ensures that the Domain layer does not have dependencies on other layers.
    /// This is crucial for maintaining the separation of concerns and ensuring that the Domain layer remains independent
    /// from Application, Infrastructure, and API layers.
    /// </summary>
    [Fact]
    public void Domain_ShouldNotHaveDependencyOn_OtherLayers()
    {
        // Act
        var result = Types.InAssembly(DomainAssembly)
            .Should()
            .NotHaveDependencyOn(ApplicationNamespace)
            .And()
            .NotHaveDependencyOn(InfrastructureNamespace)
            .And()
            .NotHaveDependencyOn(ApiNamespace)
            .GetResult();

        // Assert
        Assert.True(result.IsSuccessful, $"Domain layer should not depend on other layers. Violations: {string.Join(", ", result.FailingTypeNames ?? [])}");
    }

    [Fact]
    public void Application_ShouldOnlyDependOn_Domain()
    {
        // Act
        var result = Types.InAssembly(ApplicationAssembly)
            .Should()
            .NotHaveDependencyOn(InfrastructureNamespace)
            .And()
            .NotHaveDependencyOn(ApiNamespace)
            .GetResult();

        // Assert
        Assert.True(result.IsSuccessful, $"Application layer should not depend on Infrastructure or API. Violations: {string.Join(", ", result.FailingTypeNames ?? [])}");
    }

    [Fact]
    public void Infrastructure_ShouldNotHaveDependencyOn_Api()
    {
        // This test ensures Infrastructure doesn't depend on API layer
        var result = Types.InAssembly(InfrastructureAssembly)
            .Should()
            .NotHaveDependencyOn(ApiNamespace)
            .GetResult();

        // Assert
        Assert.True(result.IsSuccessful, $"Infrastructure should not depend on API layer. Violations: {string.Join(", ", result.FailingTypeNames ?? [])}");
    }
}
```

### Key Architecture Tests

**NetArchTest.Rules** provides a fluent API for testing architectural constraints:

- **Layer Dependencies**: Ensures Domain doesn't reference Application/Infrastructure/API
- **Application Isolation**: Application only references Domain
- **Infrastructure Boundaries**: Infrastructure doesn't reference API
- **Naming Conventions**: Can validate class/handler naming patterns
- **Sealed Classes**: Domain classes should be sealed for immutability

These tests run on every build to catch violations early.

---

## Project Structure Best Practices

### Domain Layer
```
Domain/
  IDomainMarker.cs
  Orders/
    Order.cs                    ← Aggregate root
    OrderLine.cs                ← Entity (owned by Order)
    OrderStatus.cs              ← Enum/Value Object
    OrderId.cs                  ← Strongly typed ID
    IOrderRepository.cs         ← Repository interface (NO implementation)
  Shared/
    DomainException.cs
    ValueObject.cs
```

**Rules:**
- No EF Core, no System.Data, no HTTP
- Interfaces only (implementations in Infrastructure)
- Business logic lives here

### Application Layer
```
Application/
  IApplicationMarker.cs
  Shared/
    ICommandHandler.cs
    IQueryHandler.cs
  Features/
    PlaceOrder/
      PlaceOrderCommand.cs
      PlaceOrderCommandHandler.cs
    GetOrder/
      GetOrderQuery.cs
      GetOrderQueryHandler.cs
      OrderViewModel.cs
```

**Rules:**
- References Domain only
- No Infrastructure implementations
- Orchestrates use cases

### Infrastructure Layer
```
Infrastructure/
  IInfrastructureMarker.cs
  Persistence/
    OrderingDbContext.cs
    Repositories/
      OrderRepository.cs        ← Implements IOrderRepository
  Services/
    InventoryService.cs         ← Implements IInventoryService
  DependencyInjection.cs        ← Convention-based DI registration
```

**Rules:**
- Implements interfaces from Domain/Application
- References EF Core, HTTP clients, etc.
- Registers handlers via convention

### API Layer
```
Api/
  IApiMarker.cs
  Orders/
    OrdersEndpoints.cs          ← Minimal API endpoints
  Program.cs
```

**Rules:**
- Does NOT reference Application assembly
- Injects `ICommandHandler<>` / `IQueryHandler<>`
- Infrastructure resolves handlers

---

## Testing Strategy

### UnitTests (Application Layer)

Test handlers with real Domain objects, mock only Infrastructure:

```csharp
// UnitTests/Application/Orders/Commands/PlaceOrderCommandHandlerTests.cs
[Fact]
public async Task WhenPlacingValidOrder_ShouldCreateConfirmedOrder()
{
    // Arrange - Mock only Infrastructure
    var orderRepository = A.Fake<IOrderRepository>();
    var inventoryService = A.Fake<IInventoryService>();
    var handler = new PlaceOrderCommandHandler(orderRepository, inventoryService);

    var command = new PlaceOrderCommand(/*...*/);

    // Act - Handler uses REAL Domain objects
    var orderId = await handler.HandleAsync(command);

    // Assert - Verify Infrastructure calls AND Domain state
    A.CallTo(() => orderRepository.AddAsync(
        A<Order>.That.Matches(o => o.Status == OrderStatus.Confirmed),
        A<CancellationToken>._
    )).MustHaveHappenedOnceExactly();
}
```

**REQUIRED SUB-SKILL:** Use application-layer-testing for complete handler testing strategy.

### ArchitectureTests

Run architecture validation tests to enforce layer dependencies:

```bash
dotnet test --filter "FullyQualifiedName~ArchitectureTests"
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| **API references Application assembly** | API should only reference Infrastructure + Domain. Handler interfaces injected via DI, not direct assembly reference. |
| **Domain references EF Core/System.Data** | Domain must have ZERO external deps. Use repository interfaces only. |
| **ViewModels named `*Dto`** | Must end with `ViewModel` for convention-based discovery: `OrderViewModel` not `OrderDto`. |
| **Handlers missing suffix** | Auto-discovery requires exact naming: `PlaceOrderCommandHandler`, `GetOrderQueryHandler`. |
| **Handler not registered in DI** | Verify naming convention matches discovery logic in `DependencyInjection.cs`. |
| **Application references Infrastructure** | Application should only know Domain. Infrastructure implements interfaces. |
| **Multiple aggregates in one repository** | One repository per aggregate root only. No generic `Repository<T>`. |
| **Business logic in handlers** | Handlers orchestrate. Business rules belong in Domain aggregates. |

### IntegrationTests (API Layer + Architecture Validation)

Test endpoints with WebApplicationFactory and validate architecture rules:

```csharp
// IntegrationTests/Api/Orders/PlaceOrderEndpointTests.cs
[Fact]
public async Task PlaceOrder_ShouldReturn201Created()
{
    // Arrange
    var client = _factory.CreateClient();
    var command = new PlaceOrderCommand(/*...*/);

    // Act
    var response = await client.PostAsJsonAsync("/api/orders", command);

    // Assert
    Assert.Equal(HttpStatusCode.Created, response.StatusCode);
}
```

Architecture tests run on every build to catch violations:

```bash
dotnet test --filter "FullyQualifiedName~IntegrationTests"
```

---

## References

- **[layer-responsibilities.md](references/layer-responsibilities.md)**: Detailed responsibilities for each layer
- **[convention-based-di.md](references/convention-based-di.md)**: Assembly scanning strategies

---

## Quick Reference

| Task | Pattern | Example |
|------|---------|------|
| **Create command** | `[Action]Command.cs` | `PlaceOrderCommand` |
| **Create command handler** | `[Action]CommandHandler.cs` | `PlaceOrderCommandHandler` |
| **Create query** | `[Action]Query.cs` | `GetOrderQuery` |
| **Create query handler** | `[Action]QueryHandler.cs` | `GetOrderQueryHandler` |
| **Create view model** | `[Entity]ViewModel.cs` | `OrderViewModel` |
| **Initialize project** | `./scripts/init-project.sh "Name"` | Creates full structure |
| **Run architecture tests** | `dotnet test --filter ArchitectureTests` | Validates layer rules |
| **Watch tests** | `dotnet watch test` | Auto-run on changes |

### Layer Dependencies (Must Follow)

| Layer | Can Reference | Cannot Reference |
|-------|---------------|------------------|
| **Domain** | Nothing | Application, Infrastructure, API |
| **Application** | Domain only | Infrastructure, API |
| **Infrastructure** | Domain, Application | API |
| **API** | Infrastructure, Domain | Application (handlers via DI only) |


---

## Related Skills

- **REQUIRED SUB-SKILL:** application-layer-testing - How to test Application handlers with sociable testing

