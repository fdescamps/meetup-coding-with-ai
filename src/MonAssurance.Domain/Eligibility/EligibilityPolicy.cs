namespace MonAssurance.Domain.Eligibility;

public sealed class EligibilityPolicy
{
    public EligibilityResult Evaluate(Driver driver, Vehicle vehicle, DateOnly today)
    {
        if (driver.Age(today) < vehicle.MinimumAge())
            return EligibilityResult.Refused("Conducteur trop jeune pour ce véhicule");

        return EligibilityResult.Accepted();
    }
}
