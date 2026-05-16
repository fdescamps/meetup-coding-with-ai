namespace MonAssurance.Domain.Eligibility;

public sealed class Vehicle
{
    private readonly VehicleType _type;
    private readonly int? _power;

    public Vehicle(VehicleType type, int? power)
    {
        _type = type;
        _power = power;
    }

    public int MinimumAge() => 99; // stub — intentionally wrong

    public bool IsHighPowerMotorcycle() => false; // stub
}
