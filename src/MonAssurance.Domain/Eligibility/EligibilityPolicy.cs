namespace MonAssurance.Domain.Eligibility;

public sealed class EligibilityPolicy
{
    public EligibilityResult Evaluate(Driver driver, Vehicle vehicle, DateOnly today)
    {
        if (driver.Age(today) < vehicle.MinimumAge())
            return EligibilityResult.Refused("Conducteur trop jeune pour ce véhicule");

        if (vehicle.IsHighPowerMotorcycle() && !driver.HasEnoughExperience(5))
            return EligibilityResult.Refused("Expérience insuffisante pour la puissance");

        return EligibilityResult.Accepted();
    }
}
