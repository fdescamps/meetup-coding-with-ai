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

    public int MinimumAge() => _type == VehicleType.ElectricScooter ? 16 : 18;

    // Convention: null power treated as < 100hp — no experience rule triggered.
    public bool IsHighPowerMotorcycle() => _type == VehicleType.Motorcycle && _power > 100;
}
