// tests/MonAssurance.UnitTests/Eligibility/Application/CheckEligibilityQueryHandlerTests.cs
using Microsoft.Extensions.Time.Testing;
using MonAssurance.Application.Eligibility.Queries.CheckEligibility;
using MonAssurance.Domain.Eligibility;

namespace MonAssurance.UnitTests.Eligibility.Application;

public class CheckEligibilityQueryHandlerTests
{
    private static readonly DateOnly Today = new(2026, 1, 1);

    private static CheckEligibilityQueryHandler BuildHandler(DateOnly today)
    {
        var fakeTime = new FakeTimeProvider();
        fakeTime.SetUtcNow(today.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc));
        return new CheckEligibilityQueryHandler(new EligibilityPolicy(), fakeTime);
    }

    [Fact]
    public void Handle_WhenDriverIs18AndHasCar_ReturnsEligible()
    {
        var handler = BuildHandler(Today);
        var query = new CheckEligibilityQuery(
            DateOfBirth: Today.AddYears(-18),
            VehicleType: VehicleType.Car,
            Power: null,
            LicenseYears: 2);

        var result = handler.Handle(query);

        Assert.True(result.IsEligible);
        Assert.Null(result.RejectionReason);
    }
}
