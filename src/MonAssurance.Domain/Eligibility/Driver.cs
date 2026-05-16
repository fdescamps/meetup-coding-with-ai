namespace MonAssurance.Domain.Eligibility;

public sealed class Driver
{
    private readonly DateOnly _dateOfBirth;
    private readonly int _licenseYears;

    public Driver(DateOnly dateOfBirth, int licenseYears)
    {
        _dateOfBirth = dateOfBirth;
        _licenseYears = licenseYears;
    }

    public int Age(DateOnly today) => 0; // stub

    public bool HasEnoughExperience(int minimumYears) => false; // stub
}
