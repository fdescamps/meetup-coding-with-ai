namespace MonAssurance.Application.Eligibility.Queries.CheckEligibility;

public sealed class EligibilityViewModel
{
    public bool IsEligible { get; }
    public string? RejectionReason { get; }

    private EligibilityViewModel(bool isEligible, string? reason)
    {
        IsEligible = isEligible;
        RejectionReason = reason;
    }

    public static EligibilityViewModel Accepted() => new(true, null);
    public static EligibilityViewModel Refused(string reason) => new(false, reason);
}
