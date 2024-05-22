using System.Data;
using BazyDanych.Data;
using BazyDanych.Data.Models;
using Dapper;

namespace BazyDanych.Repositories;

public class EmployeeRepository
{
    private readonly DapperContext _context;

    public EmployeeRepository(DapperContext context)
    {
        _context = context;
    }
    
    public async Task<List<EmployeeModel>> GetAllEmployeeModelsAsync()
    {
        const string query = """
                                 SELECT
                                     e.imie AS FirstName,
                                     e.drugie_imie AS SecondName,
                                     e.nazwisko AS LastName,
                                     e.login as Login,
                                     e.id_pracownika as Id,
                                     p.zarobki as Salary,
                                     p.nazwa AS PositionName,
                                     u.uprawnienia AS Permissions
                                 FROM public."Pracownik" e
                                 JOIN public."Stanowisko" p ON e.id_stanowiska = p.id_stanowiska
                                 JOIN public."Uprawnienia" u ON p.id_uprawnien = u.id_uprawnien
                                 ORDER BY e.id_pracownika
                             """;

        using var connection = _context.CreateRootConnection();

        var results = await connection.QueryAsync(query);
        var employees = new List<EmployeeModel>();

        foreach (var result in results)
        {
            var permissions = new PermissionsModel(result.permissions);
            var position = new PositionModel(result.positionname, permissions);
            var employee = new EmployeeModel(result.id, result.firstname, result.secondname, result.lastname, result.login,
                result.salary, position);

            employees.Add(employee);
        }

        return employees;
    }
    
    public async Task<EmployeeModel?> GetEmployeeModelAsync(UserCredentials credentials)
    {
        const string query = """
                                 SELECT
                                     e.imie AS FirstName,
                                     e.drugie_imie AS SecondName,
                                     e.nazwisko AS LastName,
                                     e.login as Login,
                                     e.id_pracownika as Id,
                                     p.zarobki as Salary,
                                     p.nazwa AS PositionName,
                                     u.uprawnienia AS Permissions
                                 FROM public."Pracownik" e
                                 JOIN public."Stanowisko" p ON e.id_stanowiska = p.id_stanowiska
                                 JOIN public."Uprawnienia" u ON p.id_uprawnien = u.id_uprawnien
                                 WHERE e.login = @Username AND haslo = @Password
                             """;

        using var connection = _context.CreateRootConnection();

        var result = await connection.QueryFirstOrDefaultAsync(query, credentials);
        if (result is null)
        {
            return null;
        }

        var permissions = new PermissionsModel(result.permissions);
        var position = new PositionModel(result.positionname, permissions);
        var employee = new EmployeeModel(result.id, result.firstname, result.secondname, result.lastname, result.login,
            result.salary, position);

        return employee;
    }

    public async Task ChangePasswordAsync(int employeeId, string oldPassword, string newPassword)
    {
        const string procedure = "zmiana_hasla";

        using var connection = _context.CreateRootConnection();
        var parameters = new
        {
            id_temp = employeeId,
            stare_haslo = oldPassword,
            nowe_haslo = newPassword
        };

        await connection.ExecuteAsync(procedure, parameters, commandType: CommandType.StoredProcedure);
    }
}
