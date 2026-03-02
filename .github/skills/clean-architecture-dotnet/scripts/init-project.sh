#!/usr/bin/env bash

#
# Initializes a Clean Architecture CQRS project structure for .NET
#
# Usage: ./init-project.sh "ProjectName"
# Example: ./init-project.sh "Ordering"
#

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "❌ Error: Project name required"
    echo "Usage: $0 <ProjectName>"
    echo "Example: $0 Ordering"
    exit 1
fi

PROJECT_NAME="$1"

echo "🚀 Initializing Clean Architecture CQRS project: $PROJECT_NAME"

# Create solution
echo ""
echo "📦 Creating solution..."
dotnet new sln -n "$PROJECT_NAME"

# Create src directory structure
echo ""
echo "📁 Creating source projects..."
mkdir -p src

# Domain layer
dotnet new classlib -n "$PROJECT_NAME.Domain" -o "src/$PROJECT_NAME.Domain" -f net10.0
rm -f "src/$PROJECT_NAME.Domain/Class1.cs"
dotnet sln add "src/$PROJECT_NAME.Domain/$PROJECT_NAME.Domain.csproj"

# Application layer
dotnet new classlib -n "$PROJECT_NAME.Application" -o "src/$PROJECT_NAME.Application" -f net10.0
rm -f "src/$PROJECT_NAME.Application/Class1.cs"
dotnet sln add "src/$PROJECT_NAME.Application/$PROJECT_NAME.Application.csproj"

# Infrastructure layer
dotnet new classlib -n "$PROJECT_NAME.Infrastructure" -o "src/$PROJECT_NAME.Infrastructure" -f net10.0
rm -f "src/$PROJECT_NAME.Infrastructure/Class1.cs"
dotnet sln add "src/$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj"

# API layer
dotnet new web -n "$PROJECT_NAME.Api" -o "src/$PROJECT_NAME.Api" -f net10.0
dotnet sln add "src/$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj"

# Create tests directory structure
echo ""
echo "🧪 Creating test projects..."
mkdir -p tests

# UnitTests
dotnet new xunit -n "$PROJECT_NAME.UnitTests" -o "tests/$PROJECT_NAME.UnitTests" -f net10.0
dotnet sln add "tests/$PROJECT_NAME.UnitTests/$PROJECT_NAME.UnitTests.csproj"

# IntegrationTests
dotnet new xunit -n "$PROJECT_NAME.IntegrationTests" -o "tests/$PROJECT_NAME.IntegrationTests" -f net10.0
dotnet sln add "tests/$PROJECT_NAME.IntegrationTests/$PROJECT_NAME.IntegrationTests.csproj"

# Add project references
echo ""
echo "🔗 Configuring project references..."

# Application -> Domain
dotnet add "src/$PROJECT_NAME.Application/$PROJECT_NAME.Application.csproj" reference "src/$PROJECT_NAME.Domain/$PROJECT_NAME.Domain.csproj"

# Infrastructure -> Application, Domain
dotnet add "src/$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" reference "src/$PROJECT_NAME.Application/$PROJECT_NAME.Application.csproj"
dotnet add "src/$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj" reference "src/$PROJECT_NAME.Domain/$PROJECT_NAME.Domain.csproj"

# API -> Infrastructure, Domain (NOT Application)
dotnet add "src/$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj" reference "src/$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj"
dotnet add "src/$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj" reference "src/$PROJECT_NAME.Domain/$PROJECT_NAME.Domain.csproj"

# UnitTests -> Application, Domain
dotnet add "tests/$PROJECT_NAME.UnitTests/$PROJECT_NAME.UnitTests.csproj" reference "src/$PROJECT_NAME.Application/$PROJECT_NAME.Application.csproj"
dotnet add "tests/$PROJECT_NAME.UnitTests/$PROJECT_NAME.UnitTests.csproj" reference "src/$PROJECT_NAME.Domain/$PROJECT_NAME.Domain.csproj"

# IntegrationTests -> All layers (API for endpoint tests, all layers for architecture tests)
dotnet add "tests/$PROJECT_NAME.IntegrationTests/$PROJECT_NAME.IntegrationTests.csproj" reference "src/$PROJECT_NAME.Api/$PROJECT_NAME.Api.csproj"
dotnet add "tests/$PROJECT_NAME.IntegrationTests/$PROJECT_NAME.IntegrationTests.csproj" reference "src/$PROJECT_NAME.Domain/$PROJECT_NAME.Domain.csproj"
dotnet add "tests/$PROJECT_NAME.IntegrationTests/$PROJECT_NAME.IntegrationTests.csproj" reference "src/$PROJECT_NAME.Application/$PROJECT_NAME.Application.csproj"
dotnet add "tests/$PROJECT_NAME.IntegrationTests/$PROJECT_NAME.IntegrationTests.csproj" reference "src/$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj"

# Add NuGet packages
echo ""
echo "📦 Adding NuGet packages..."

# UnitTests packages
dotnet add "tests/$PROJECT_NAME.UnitTests/$PROJECT_NAME.UnitTests.csproj" package FakeItEasy

# IntegrationTests packages
dotnet add "tests/$PROJECT_NAME.IntegrationTests/$PROJECT_NAME.IntegrationTests.csproj" package Microsoft.AspNetCore.Mvc.Testing
dotnet add "tests/$PROJECT_NAME.IntegrationTests/$PROJECT_NAME.IntegrationTests.csproj" package NetArchTest.Rules

# Create directory structure
echo ""
echo "📂 Creating directory structure..."

# Domain
mkdir -p "src/$PROJECT_NAME.Domain/Shared"

# Application  
mkdir -p "src/$PROJECT_NAME.Application/features"

# Infrastructure
mkdir -p "src/$PROJECT_NAME.Infrastructure/Persistence/Repositories"
mkdir -p "src/$PROJECT_NAME.Infrastructure/Services"

# API
# No additional directories needed

# UnitTests
mkdir -p "tests/$PROJECT_NAME.UnitTests/Application"

# IntegrationTests
mkdir -p "tests/$PROJECT_NAME.IntegrationTests/Api"

# Create marker interfaces
echo ""
echo "📄 Creating marker interfaces..."

cat > "src/$PROJECT_NAME.Domain/IDomainMarker.cs" <<EOF
namespace $PROJECT_NAME.Domain;

/// <summary>
/// Marker interface to identify the Domain assembly.
/// Use: typeof(IDomainMarker).Assembly
/// </summary>
public interface IDomainMarker { }
EOF

cat > "src/$PROJECT_NAME.Application/IApplicationMarker.cs" <<EOF
namespace $PROJECT_NAME.Application;

/// <summary>
/// Marker interface to identify the Application assembly.
/// Use: typeof(IApplicationMarker).Assembly
/// </summary>
public interface IApplicationMarker { }
EOF

# Create CQRS interfaces in features
echo ""
echo "📝 Creating CQRS handler interfaces..."

cat > "src/$PROJECT_NAME.Application/features/ICommandHandler.cs" <<EOF
namespace $PROJECT_NAME.Application.features;

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
EOF

cat > "src/$PROJECT_NAME.Application/features/IQueryHandler.cs" <<EOF
namespace $PROJECT_NAME.Application.features;

/// <summary>
/// Handler for queries (read operations).
/// </summary>
public interface IQueryHandler<in TQuery, TResult>
{
    Task<TResult> HandleAsync(TQuery query, CancellationToken cancellationToken = default);
}
EOF

# Create marker interfaces for Infrastructure and API
cat > "src/$PROJECT_NAME.Infrastructure/IInfrastructureMarker.cs" <<EOF
namespace $PROJECT_NAME.Infrastructure;

/// <summary>
/// Marker interface to identify the Infrastructure assembly.
/// Use: typeof(IInfrastructureMarker).Assembly
/// </summary>
public interface IInfrastructureMarker { }
EOF

cat > "src/$PROJECT_NAME.Api/IApiMarker.cs" <<EOF
namespace $PROJECT_NAME.Api;

/// <summary>
/// Marker interface to identify the API assembly.
/// Use: typeof(IApiMarker).Assembly
/// </summary>
public interface IApiMarker { }
EOF

# Copy Architecture test template to IntegrationTests
echo ""
echo "🏛️ Creating architecture tests..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates/IntegrationTests"

if [ -d "$TEMPLATES_DIR" ]; then
    cp "$TEMPLATES_DIR/ArchitectureTests.cs" "tests/$PROJECT_NAME.IntegrationTests/ArchitectureTests.cs" 2>/dev/null || true
    
    # Replace placeholder project name in template
    if [ -f "tests/$PROJECT_NAME.IntegrationTests/ArchitectureTests.cs" ]; then
        sed -i.bak "s/\[ProjectName\]/$PROJECT_NAME/g" "tests/$PROJECT_NAME.IntegrationTests/ArchitectureTests.cs"
        rm -f "tests/$PROJECT_NAME.IntegrationTests/ArchitectureTests.cs.bak"
    fi
fi

# Build to verify
echo ""
echo "🔨 Building solution..."
dotnet build

echo ""
echo "✅ Clean Architecture CQRS project initialized successfully!"
echo ""
echo "Next steps:"
echo "  1. Review src/$PROJECT_NAME.Domain for business logic"
echo "  2. Create Commands/Queries in src/$PROJECT_NAME.Application/features/"
echo "  3. Implement handlers with *CommandHandler/*QueryHandler suffix"
echo "  4. Run architecture tests: dotnet test --filter 'FullyQualifiedName~IntegrationTests'"
echo ""
echo "📚 See .github/skills/clean-architecture-dotnet/SKILL.md for complete guide"
