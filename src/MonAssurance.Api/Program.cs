using MonAssurance.Api.Eligibility;
using MonAssurance.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddInfrastructure();
builder.Services.AddSingleton(TimeProvider.System);

// Add Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new()
    {
        Title = "MonAssurance API",
        Version = "v3",
        Description = "Clean Architecture CQRS API for MonAssurance"
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Map endpoints
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
    .WithName("HealthCheck")
    .Produces(StatusCodes.Status200OK);

app.MapEligibilityEndpoints();

app.Run();

// Make the implicit Program class public for WebApplicationFactory
public partial class Program { }
