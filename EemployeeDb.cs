using System.Data;
using Dapper;
using Npgsql;

public sealed record EmployeeSearchRow(
    string UserId,
    string Name,
    string Email,
    string? Image,
    string Status,
    string? ManagerId,
    string? ManagerName,
    string? EmployeeNumber,
    string? Department,
    string? EmploymentType,
    decimal? Salary,
    decimal? HourlyRate,
    DateTimeOffset? LastLoginAt,
    string RolesJson,
    string TeamsJson,
    long TotalCount
);

public sealed class EmployeeDb
{
    private readonly string _connectionString;

    public EmployeeDb(string connectionString) => _connectionString = connectionString;

    public async Task<IReadOnlyList<EmployeeSearchRow>> SearchEmployeesAsync(
        string? search,
        int limit,
        int offset,
        string? roleId,
        string? teamId,
        string? status,
        bool noRoles,
        bool noTeam,
        bool hasPayData,
        CancellationToken ct = default)
    {
        const string sql = """
            SELECT * FROM crm_search_employees_optimized(
                @p_search, @p_limit, @p_offset, @p_role_id, @p_team_id, @p_status, @p_no_roles, @p_no_team, @p_has_pay_data
            );
            """;

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync(ct);

        var rows = await conn.QueryAsync<EmployeeSearchRow>(
            new CommandDefinition(
                sql,
                new
                {
                    p_search = search,
                    p_limit = limit,
                    p_offset = offset,
                    p_role_id = roleId,
                    p_team_id = teamId,
                    p_status = status,
                    p_no_roles = noRoles,
                    p_no_team = noTeam,
                    p_has_pay_data = hasPayData
                },
                cancellationToken: ct
            )
        );

        return rows.AsList();
    }

    public async Task SyncMembershipsAsync(
        string userId,
        string[] roleIds,
        string[] teamIds,
        CancellationToken ct = default)
    {
        const string sql = "CALL crm_sync_employee_memberships(@p_user_id, @p_role_ids, @p_team_ids);";

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync(ct);

        await conn.ExecuteAsync(
            new CommandDefinition(
                sql,
                new
                {
                    p_user_id = userId,
                    p_role_ids = roleIds,
                    p_team_ids = teamIds
                },
                cancellationToken: ct
            )
        );
    }

    public async Task<(bool MassAccess, string[] Pages)?> GetEffectivePermissionsAsync(string userId, CancellationToken ct = default)
    {
        const string sql = "SELECT * FROM crm_get_effective_permissions(@p_user_id);";

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync(ct);

        var row = await conn.QueryFirstOrDefaultAsync<(string UserId, bool MassAccess, string[] Pages)>(
            new CommandDefinition(sql, new { p_user_id = userId }, cancellationToken: ct)
        );

        if (row.UserId is null) return null;
        return (row.MassAccess, row.Pages);
    }
}
