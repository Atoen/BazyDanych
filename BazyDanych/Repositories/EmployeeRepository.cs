using System.Data;
using BazyDanych.Data;
using BazyDanych.Data.Models;
using BazyDanych.Services;
using Dapper;

namespace BazyDanych.Repositories;

public class EmployeeRepository
{
    private readonly DapperContext _context;
    private readonly PasswordHasher _passwordHasher;

    public EmployeeRepository(DapperContext context, PasswordHasher passwordHasher)
    {
        _context = context;
        _passwordHasher = passwordHasher;
    }

    public async Task<IEnumerable<EmployeeModel>> GetAllEmployeeModelsAsync(PermissionsModel? permissionsModel)
    {
        const string query = """
                                 SELECT
                                     e.imie AS FirstName,
                                     e.drugie_imie AS SecondName,
                                     e.nazwisko AS LastName,
                                     e.login as Login,
                                     e.haslo as Password,
                                     e.id_pracownika as Id,
                                     p.zarobki as Salary,
                                     p.nazwa AS PositionName,
                                     p.id_stanowiska AS PositionId,
                                     u.uprawnienia AS Permissions
                                 FROM public."Pracownik" e
                                 JOIN public."Stanowisko" p ON e.id_stanowiska = p.id_stanowiska
                                 JOIN public."Uprawnienia" u ON p.id_uprawnien = u.id_uprawnien
                                 ORDER BY e.id_pracownika
                             """;

        if (permissionsModel is null) return [];
        using var connection = _context.CreateUserConnection(permissionsModel);

        var results = await connection.QueryAsync(query);
        var employees = new List<EmployeeModel>();

        foreach (var result in results)
        {
            var permissions = new PermissionsModel(result.permissions);
            var position = new PositionModel(result.positionid, result.positionname, result.salary, permissions);
            var employee = new EmployeeModel(result.id, result.firstname, result.secondname, result.lastname, result
                .login, result.password, position);

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
                                     e.haslo as Password,
                                     e.id_pracownika as Id,
                                     p.zarobki as Salary,
                                     p.nazwa AS PositionName,
                                     p.id_stanowiska AS PositionId,
                                     u.uprawnienia AS Permissions
                                 FROM public."Pracownik" e
                                 JOIN public."Stanowisko" p ON e.id_stanowiska = p.id_stanowiska
                                 JOIN public."Uprawnienia" u ON p.id_uprawnien = u.id_uprawnien
                                 WHERE e.login = @Username AND haslo = @Password
                             """;

        using var connection = _context.CreateRootConnection();

        var param = new
        {
            credentials.Username,
            Password = _passwordHasher.HashPassword(credentials.Password)
        };
        
        
        var result = await connection.QueryFirstOrDefaultAsync(query, param);
        
        if (result is null)
        {
            return null;
        }

        var permissions = new PermissionsModel(result.permissions);
        var position = new PositionModel(result.positionid, result.positionname, result.salary, permissions);
        var employee = new EmployeeModel(result.id, result.firstname, result.secondname, result.lastname, result
            .login, result.password, position);

        return employee;
    }

    public async Task ModifyEmployeeAsync(EmployeeModel employee, PermissionsModel? permissionsModel)
    {
        const string employeeQuery = """
                                     UPDATE public."Pracownik"
                                     SET
                                         imie = @FirstName,
                                         drugie_imie = @SecondName,
                                         nazwisko = @LastName,
                                         login = @Login,
                                         haslo = @Password
                                     WHERE
                                         id_pracownika = @Id
                                     """;

        const string positionQuery = """
                                     UPDATE public."Stanowisko"
                                     SET
                                         nazwa = @PositionName,
                                         zarobki = @Salary,
                                         id_uprawnien = @PermissionsId
                                     WHERE
                                         id_stanowiska = @PositionId
                                     """;

        if (permissionsModel is null) return;
        using var connection = _context.CreateUserConnection(permissionsModel);
        connection.Open();

        using var transaction = connection.BeginTransaction();

        try
        {
            await connection.ExecuteAsync(employeeQuery, new
            {
                employee.FirstName,
                employee.SecondName,
                employee.LastName,
                employee.Login,
                employee.Id,
                Password = _passwordHasher.HashPassword(employee.Password)
            }, transaction);

            await connection.ExecuteAsync(positionQuery, new
            {
                PositionName = employee.Position.Name,
                employee.Position.Salary,
                PermissionsId = employee.Position.Permissions.DatabaseId,
                PositionId = employee.Position.Id
            }, transaction);

            transaction.Commit();
        }
        catch (Exception e)
        {
            transaction.Rollback();

            Console.WriteLine(e);
            throw;
        }
    }

    public async Task<int> AddEmployeeAsync(EmployeeModel employee, PermissionsModel? permissionsModel)
    {
        const string employeeInsertQuery = """
                                           INSERT INTO public."Pracownik" (imie, drugie_imie, nazwisko, login, haslo, id_stanowiska)
                                           VALUES (@FirstName, @SecondName, @LastName, @Login, @Password, @PositionId)
                                           RETURNING id_pracownika
                                           """;

        const string positionInsertQuery = """
                                           INSERT INTO public."Stanowisko" (nazwa, zarobki, id_uprawnien)
                                           VALUES (@PositionName, @Salary, @PermissionsId)
                                           RETURNING id_stanowiska
                                           """;

        if (permissionsModel is null) return 0;
        
        using var connection = _context.CreateUserConnection(permissionsModel);
        connection.Open();

        using var transaction = connection.BeginTransaction();

        try
        {
            var positionId = await connection.ExecuteScalarAsync<int>(positionInsertQuery, new
            {
                PositionName = employee.Position.Name,
                employee.Position.Salary,
                PermissionsId = employee.Position.Permissions.DatabaseId
            }, transaction);
            
            var employeeId = await connection.ExecuteScalarAsync<int>(employeeInsertQuery, new
            {
                employee.FirstName,
                employee.SecondName,
                employee.LastName,
                employee.Login,
                employee.Password,
                PositionId = positionId
            }, transaction);

            transaction.Commit();
            return employeeId; 
        }
        catch (Exception e)
        {
            transaction.Rollback();
            Console.WriteLine(e);
            throw;
        }
    }
    
    public async Task ChangePasswordAsync(int employeeId, string oldPassword, string newPassword, PermissionsModel? permissionsModel)
    {
        const string procedure = "zmiana_hasla";

        if (permissionsModel is null) return;
        using var connection = _context.CreateUserConnection(permissionsModel);
        var parameters = new
        {
            id_temp = employeeId,
            stare_haslo = _passwordHasher.HashPassword(oldPassword),
            nowe_haslo = _passwordHasher.HashPassword(newPassword)
        };

        await connection.ExecuteAsync(procedure, parameters, commandType: CommandType.StoredProcedure);
    }
}