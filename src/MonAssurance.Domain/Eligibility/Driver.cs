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

    public int Age(DateOnly today)
    {
        var age = today.Year - _dateOfBirth.Year;
        if (today < _dateOfBirth.AddYears(age)) age--;
        return age;
    }

    public bool HasEnoughExperience(int minimumYears) => _licenseYears >= minimumYears;
}
