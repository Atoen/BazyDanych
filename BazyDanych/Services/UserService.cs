using BazyDanych.Data.Models;
using BazyDanych.Data.Resutls;
using BazyDanych.Repositories;

namespace BazyDanych.Services;

public class UserService
{
    public bool IsAuthenticated { get; private set; }
    
    public EmployeeModel? Employee { get; private set; }
    public PermissionsModel? EmployeePermissions => Employee?.Position.Permissions;

    private readonly EmployeeRepository _employeeRepository;
    private readonly RedirectManager _redirectManager;
    private readonly ILogger<UserService> _logger;

    public UserService(
        EmployeeRepository employeeRepository,
        RedirectManager redirectManager,
        ILogger<UserService> logger)
    {
        _employeeRepository = employeeRepository;
        _redirectManager = redirectManager;
        _logger = logger;
    }
    
    public async Task<LoginResult> LoginAsync(UserCredentials credentials)
    {
        var result  = await _employeeRepository.GetEmployeeModelAsync(credentials);
        if (result == null)
        {
            return LoginResult.Failed;
        }

        Employee = result;
        IsAuthenticated = true;
        
        _logger.LogInformation("User {Username} logged in", Employee.FullName);
        
        return LoginResult.Success;
    }

    public void Logout()
    {
        _redirectManager.RedirectToLogin();

        Employee = null;
        IsAuthenticated = false;
        
        _logger.LogInformation("User logged out");
        
    }
}