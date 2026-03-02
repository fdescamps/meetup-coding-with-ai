#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Initializes a Clean Architecture CQRS project structure for .NET.

.DESCRIPTION
    Creates a complete solution with Domain, Application, Infrastructure, and API layers,
    plus UnitTests, IntegrationTests, and ArchitectureTests projects.
    
.PARAMETER ProjectName
    The name of the project (e.g., "Ordering", "Catalog").
    
.EXAMPLE
    .\init-project.ps1 -ProjectName "Ordering"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Initializing Clean Architecture CQRS project: $ProjectName" -ForegroundColor Cyan

# Create solution
Write-Host "`n📦 Creating solution..." -ForegroundColor Yellow
dotnet new sln -n $ProjectName

# Create src directory structure
Write-Host "`n📁 Creating source projects..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "src" | Out-Null

# Domain layer
dotnet new classlib -n "$ProjectName.Domain" -o "src/$ProjectName.Domain" -f net10.0
Remove-Item "src/$ProjectName.Domain/Class1.cs" -Force
dotnet sln add "src/$ProjectName.Domain/$ProjectName.Domain.csproj"

# Application layer
dotnet new classlib -n "$ProjectName.Application" -o "src/$ProjectName.Application" -f net10.0
Remove-Item "src/$ProjectName.Application/Class1.cs" -Force
dotnet sln add "src/$ProjectName.Application/$ProjectName.Application.csproj"

# Infrastructure layer
dotnet new classlib -n "$ProjectName.Infrastructure" -o "src/$ProjectName.Infrastructure" -f net10.0
Remove-Item "src/$ProjectName.Infrastructure/Class1.cs" -Force
dotnet sln add "src/$ProjectName.Infrastructure/$ProjectName.Infrastructure.csproj"

# API layer
dotnet new web -n "$ProjectName.Api" -o "src/$ProjectName.Api" -f net10.0
dotnet sln add "src/$ProjectName.Api/$ProjectName.Api.csproj"

# Create tests directory structure
Write-Host "`n🧪 Creating test projects..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "tests" | Out-Null

# UnitTests
dotnet new xunit -n "$ProjectName.UnitTests" -o "tests/$ProjectName.UnitTests" -f net10.0
dotnet sln add "tests/$ProjectName.UnitTests/$ProjectName.UnitTests.csproj"

# IntegrationTests
dotnet new xunit -n "$ProjectName.IntegrationTests" -o "tests/$ProjectName.IntegrationTests" -f net10.0
dotnet sln add "tests/$ProjectName.IntegrationTests/$ProjectName.IntegrationTests.csproj"

# Add project references
Write-Host "`n🔗 Configuring project references..." -ForegroundColor Yellow

# Application -> Domain
dotnet add "src/$ProjectName.Application/$ProjectName.Application.csproj" reference "src/$ProjectName.Domain/$ProjectName.Domain.csproj"

# Infrastructure -> Application, Domain
dotnet add "src/$ProjectName.Infrastructure/$ProjectName.Infrastructure.csproj" reference "src/$ProjectName.Application/$ProjectName.Application.csproj"
dotnet add "src/$ProjectName.Infrastructure/$ProjectName.Infrastructure.csproj" reference "src/$ProjectName.Domain/$ProjectName.Domain.csproj"

# API -> Infrastructure, Domain (NOT Application)
dotnet add "src/$ProjectName.Api/$ProjectName.Api.csproj" reference "src/$ProjectName.Infrastructure/$ProjectName.Infrastructure.csproj"
dotnet add "src/$ProjectName.Api/$ProjectName.Api.csproj" reference "src/$ProjectName.Domain/$ProjectName.Domain.csproj"

# UnitTests -> Application, Domain
dotnet add "tests/$ProjectName.UnitTests/$ProjectName.UnitTests.csproj" reference "src/$ProjectName.Application/$ProjectName.Application.csproj"
dotnet add "tests/$ProjectName.UnitTests/$ProjectName.UnitTests.csproj" reference "src/$ProjectName.Domain/$ProjectName.Domain.csproj"

# IntegrationTests -> All layers (API for endpoint tests, all layers for architecture tests)
dotnet add "tests/$ProjectName.IntegrationTests/$ProjectName.IntegrationTests.csproj" reference "src/$ProjectName.Api/$ProjectName.Api.csproj"
dotnet add "tests/$ProjectName.IntegrationTests/$ProjectName.IntegrationTests.csproj" reference "src/$ProjectName.Domain/$ProjectName.Domain.csproj"
dotnet add "tests/$ProjectName.IntegrationTests/$ProjectName.IntegrationTests.csproj" reference "src/$ProjectName.Application/$ProjectName.Application.csproj"
dotnet add "tests/$ProjectName.IntegrationTests/$ProjectName.IntegrationTests.csproj" reference "src/$ProjectName.Infrastructure/$ProjectName.Infrastructure.csproj"

# Add NuGet packages
Write-Host "`n📦 Adding NuGet packages..." -ForegroundColor Yellow

# UnitTests packages
dotnet add "tests/$ProjectName.UnitTests/$ProjectName.UnitTests.csproj" package FakeItEasy

# IntegrationTests packages
dotnet add "tests/$ProjectName.IntegrationTests/$ProjectName.IntegrationTests.csproj" package Microsoft.AspNetCore.Mvc.Testing
dotnet add "tests/$ProjectName.IntegrationTests/$ProjectName.IntegrationTests.csproj" package NetArchTest.Rules

# Create directory structure
Write-Host "`n📂 Creating directory structure..." -ForegroundColor Yellow

# Domain
New-Item -ItemType Directory -Force -Path "src/$ProjectName.Domain/Shared" | Out-Null

# Application
New-Item -ItemType Directory -Force -Path "src/$ProjectName.Application/features" | Out-Null

# Infrastructure
New-Item -ItemType Directory -Force -Path "src/$ProjectName.Infrastructure/Persistence/Repositories" | Out-Null
New-Item -ItemType Directory -Force -Path "src/$ProjectName.Infrastructure/Services" | Out-Null

# UnitTests
New-Item -ItemType Directory -Force -Path "tests/$ProjectName.UnitTests/Application" | Out-Null

# IntegrationTests
New-Item -ItemType Directory -Force -Path "tests/$ProjectName.IntegrationTests/Api" | Out-Null

# Create marker interfaces
Write-Host "`n📄 Creating marker interfaces..." -ForegroundColor Yellow

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatesDir = Join-Path (Split-Path -Parent $scriptDir) "templates"

# IDomainMarker
$domainMarker = @"
namespace $ProjectName.Domain;

/// <summary>
/// Marker interface to identify the Domain assembly.
/// Use: typeof(IDomainMarker).Assembly
/// </summary>
public interface IDomainMarker { }
"@
Set-Content -Path "src/$ProjectName.Domain/IDomainMarker.cs" -Value $domainMarker

# IApplicationMarker
$applicationMarker = @"
namespace $ProjectName.Application;

/// <summary>
/// Marker interface to identify the Application assembly.
/// Use: typeof(IApplicationMarker).Assembly
/// </summary>
public interface IApplicationMarker { }
"@
Set-Content -Path "src/$ProjectName.Application/IApplicationMarker.cs" -Value $applicationMarker

# Create CQRS interfaces in features
Write-Host "`n📝 Creating CQRS handler interfaces..." -ForegroundColor Yellow

$commandHandler = @"
namespace $ProjectName.Application.features;

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
"@
Set-Content -Path "src/$ProjectName.Application/features/ICommandHandler.cs" -Value $commandHandler

$queryHandler = @"
namespace $ProjectName.Application.features;

/// <summary>
/// Handler for queries (read operations).
/// </summary>
public interface IQueryHandler<in TQuery, TResult>
{
    Task<TResult> HandleAsync(TQuery query, CancellationToken cancellationToken = default);
}
"@
Set-Content -Path "src/$ProjectName.Application/features/IQueryHandler.cs" -Value $queryHandler

# Create marker interfaces for Infrastructure and API
$infrastructureMarker = @"
namespace $ProjectName.Infrastructure;

/// <summary>
/// Marker interface to identify the Infrastructure assembly.
/// Use: typeof(IInfrastructureMarker).Assembly
/// </summary>
public interface IInfrastructureMarker { }
"@
Set-Content -Path "src/$ProjectName.Infrastructure/IInfrastructureMarker.cs" -Value $infrastructureMarker

$apiMarker = @"
namespace $ProjectName.Api;

/// <summary>
/// Marker interface to identify the API assembly.
/// Use: typeof(IApiMarker).Assembly
/// </summary>
public interface IApiMarker { }
"@
Set-Content -Path "src/$ProjectName.Api/IApiMarker.cs" -Value $apiMarker

# Copy Architecture test template to IntegrationTests
Write-Host "`n🏛️ Creating architecture tests..." -ForegroundColor Yellow

$archTestTemplatesDir = Join-Path $templatesDir "IntegrationTests"
if (Test-Path $archTestTemplatesDir) {
    Copy-Item "$archTestTemplatesDir/ArchitectureTests.cs" "tests/$ProjectName.IntegrationTests/ArchitectureTests.cs" -Force
    
    # Replace placeholder project name in template
    $content = Get-Content "tests/$ProjectName.IntegrationTests/ArchitectureTests.cs" -Raw
    $content = $content -replace '\[ProjectName\]', $ProjectName
    Set-Content "tests/$ProjectName.IntegrationTests/ArchitectureTests.cs" -Value $content
}

# Build to verify
Write-Host "`n🔨 Building solution..." -ForegroundColor Yellow
dotnet build

Write-Host "`n✅ Clean Architecture CQRS project initialized successfully!" -ForegroundColor Green
Write-Host "`nNext steps:"
Write-Host "  1. Review src/$ProjectName.Domain for business logic"
Write-Host "  2. Create Commands/Queries in src/$ProjectName.Application/features/"
Write-Host "  3. Implement handlers with *CommandHandler/*QueryHandler suffix"
Write-Host "  4. Run architecture tests: dotnet test --filter 'FullyQualifiedName~IntegrationTests'"
Write-Host "`n📚 See .github/skills/clean-architecture-dotnet/SKILL.md for complete guide"
