using MonAssurance.Domain.Eligibility;

namespace MonAssurance.Application.Eligibility.Queries.CheckEligibility;

public sealed record CheckEligibilityQuery(
    DateOnly DateOfBirth,
    VehicleType VehicleType,
    int? Power,
    int LicenseYears);
