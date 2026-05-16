using MonAssurance.Domain.Eligibility;

namespace MonAssurance.Application.Eligibility.Queries.CheckEligibility;

public sealed class CheckEligibilityQueryHandler
{
    private readonly EligibilityPolicy _policy;
    private readonly TimeProvider _timeProvider;

    public CheckEligibilityQueryHandler(EligibilityPolicy policy, TimeProvider timeProvider)
    {
        _policy = policy;
        _timeProvider = timeProvider;
    }

    public EligibilityViewModel Handle(CheckEligibilityQuery query)
    {
        var today = DateOnly.FromDateTime(_timeProvider.GetUtcNow().UtcDateTime);
        var driver = new Driver(query.DateOfBirth, query.LicenseYears);
        var vehicle = new Vehicle(query.VehicleType, query.Power);

        return _policy
            .Evaluate(driver, vehicle, today)
            .Match(
                onAccepted: () => EligibilityViewModel.Accepted(),
                onRefused: reason => EligibilityViewModel.Refused(reason)
            );
    }
}
