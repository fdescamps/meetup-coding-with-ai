namespace MonAssurance.Domain.Eligibility;

public sealed class EligibilityPolicy
{
    public EligibilityResult Evaluate(Driver driver, Vehicle vehicle, DateOnly today)
    {
        return EligibilityResult.Refused("not implemented"); // stub
    }
}
