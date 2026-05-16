using System.Reflection;
using MonAssurance.Domain.Eligibility;
using NetArchTest.Rules;
using Xunit;

namespace MonAssurance.IntegrationTests.Architecture;

public class DomainArchitectureTests
{
    private static readonly Assembly DomainAssembly = typeof(EligibilityPolicy).Assembly;

    [Fact]
    public void Domain_ShouldHaveNoFrameworkDependencies()
    {
        var result = Types.InAssembly(DomainAssembly)
            .ShouldNot()
            .HaveDependencyOnAny(
                "Microsoft.AspNetCore",
                "Microsoft.Extensions.DependencyInjection",
                "Microsoft.EntityFrameworkCore",
                "System.Net.Http",
                "MonAssurance.Application",
                "MonAssurance.Infrastructure",
                "MonAssurance.Api"
            )
            .GetResult();

        Assert.True(result.IsSuccessful,
            $"Domain has forbidden dependencies: {string.Join(", ", result.FailingTypeNames ?? [])}");
    }
}
