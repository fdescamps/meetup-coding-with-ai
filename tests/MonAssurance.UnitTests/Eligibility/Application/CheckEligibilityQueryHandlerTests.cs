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

    [Fact]
    public void Handle_WhenDriverIs17AndHasCar_ReturnsRefused()
    {
        var handler = BuildHandler(Today);
        var query = new CheckEligibilityQuery(
            DateOfBirth: Today.AddYears(-17),
            VehicleType: VehicleType.Car,
            Power: null,
            LicenseYears: 1);

        var result = handler.Handle(query);

        Assert.False(result.IsEligible);
        Assert.Equal("Conducteur trop jeune pour ce véhicule", result.RejectionReason);
    }

    [Fact]
    public void Handle_WhenDriverIs17AndHasMotorcycle_ReturnsRefused()
    {
        var handler = BuildHandler(Today);
        var query = new CheckEligibilityQuery(
            DateOfBirth: Today.AddYears(-17),
            VehicleType: VehicleType.Motorcycle,
            Power: null,
            LicenseYears: 1);

        var result = handler.Handle(query);

        Assert.False(result.IsEligible);
        Assert.Equal("Conducteur trop jeune pour ce véhicule", result.RejectionReason);
    }

    [Fact]
    public void Handle_WhenDriverIs15AndHasElectricScooter_ReturnsRefused()
    {
        var handler = BuildHandler(Today);
        var query = new CheckEligibilityQuery(
            DateOfBirth: Today.AddYears(-15),
            VehicleType: VehicleType.ElectricScooter,
            Power: null,
            LicenseYears: 0);

        var result = handler.Handle(query);

        Assert.False(result.IsEligible);
        Assert.Equal("Conducteur trop jeune pour ce véhicule", result.RejectionReason);
    }

    [Fact]
    public void Handle_WhenDriverIs16AndHasElectricScooter_ReturnsEligible()
    {
        var handler = BuildHandler(Today);
        var query = new CheckEligibilityQuery(
            DateOfBirth: Today.AddYears(-16),
            VehicleType: VehicleType.ElectricScooter,
            Power: null,
            LicenseYears: 0);

        var result = handler.Handle(query);

        Assert.True(result.IsEligible);
        Assert.Null(result.RejectionReason);
    }

    [Fact]
    public void Handle_WhenMotorcycleIsHighPowerAndDriverHas4YearsLicense_ReturnsRefused()
    {
        var handler = BuildHandler(Today);
        var query = new CheckEligibilityQuery(
            DateOfBirth: Today.AddYears(-25),
            VehicleType: VehicleType.Motorcycle,
            Power: 101,
            LicenseYears: 4);

        var result = handler.Handle(query);

        Assert.False(result.IsEligible);
        Assert.Equal("Expérience insuffisante pour la puissance", result.RejectionReason);
    }

    [Fact]
    public void Handle_WhenMotorcycleIsHighPowerAndDriverHas5YearsLicense_ReturnsEligible()
    {
        var handler = BuildHandler(Today);
        var query = new CheckEligibilityQuery(
            DateOfBirth: Today.AddYears(-25),
            VehicleType: VehicleType.Motorcycle,
            Power: 101,
            LicenseYears: 5);

        var result = handler.Handle(query);

        Assert.True(result.IsEligible);
        Assert.Null(result.RejectionReason);
    }

    [Fact]
    public void Handle_WhenMotorcycleIsExactly100HpAndDriverHas4YearsLicense_ReturnsEligible()
    {
        var handler = BuildHandler(Today);
        var query = new CheckEligibilityQuery(
            DateOfBirth: Today.AddYears(-25),
            VehicleType: VehicleType.Motorcycle,
            Power: 100,
            LicenseYears: 4);

        var result = handler.Handle(query);

        Assert.True(result.IsEligible);
        Assert.Null(result.RejectionReason);
    }
}
