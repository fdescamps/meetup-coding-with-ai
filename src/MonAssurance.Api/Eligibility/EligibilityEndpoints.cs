using MonAssurance.Application.Eligibility.Queries.CheckEligibility;

namespace MonAssurance.Api.Eligibility;

public static class EligibilityEndpoints
{
    public static IEndpointRouteBuilder MapEligibilityEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/eligibility", (
            CheckEligibilityQuery query,
            CheckEligibilityQueryHandler handler) =>
            Results.Ok(handler.Handle(query)));

        return app;
    }
}
