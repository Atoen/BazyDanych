using BazyDanych.Data;
using BazyDanych.Data.Entities;
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

    public async Task<Employee?> VerifyCredentialsAsync(UserCredentials credentials)
    {
        const string query = """
                             SELECT * FROM public."Pracownik" WHERE login = @Username AND haslo = @Password
                             """;

        using var connection = _context.CreateRootConnection();
        
        return await connection.QueryFirstOrDefaultAsync<Employee>(query, credentials);
    }

    public async Task<EmployeeModel?> GetEmployeeModelAsync(UserCredentials credentials)
    {
        const string query = """
                                 SELECT
                                     e.imie AS FirstName,
                                     e.drugie_imie AS SecondName,
                                     e.nazwisko AS LastName,
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
        var employee = new EmployeeModel(result.firstname, result.secondname, result.lastname, position);
        
        return employee;
    }
}