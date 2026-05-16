namespace MonAssurance.Domain.Eligibility;

public sealed class EligibilityResult
{
    private readonly bool _isEligible;
    private readonly string? _reason;

    private EligibilityResult(bool isEligible, string? reason)
    {
        _isEligible = isEligible;
        _reason = reason;
    }

    public static EligibilityResult Accepted() => new(true, null);
    public static EligibilityResult Refused(string reason) => new(false, reason);

    public T Match<T>(Func<T> onAccepted, Func<string, T> onRefused) =>
        _isEligible ? onAccepted() : onRefused(_reason!);
}
