using BazyDanych.Data.Models;

namespace BazyDanych.Extensions;

public static class EmployeeExtensions
{
    public static string GetFullName(this EmployeeModel employee)
    {
        return employee.SecondName is { } middleName
            ? $"{employee.FirstName} {middleName} {employee.LastName}"
            : $"{employee.FirstName} {employee.LastName}";
    }
}