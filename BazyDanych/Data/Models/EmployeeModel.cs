using BazyDanych.Extensions;

namespace BazyDanych.Data.Models;

public record EmployeeModel(
    int Id,
    string FirstName,
    string? SecondName,
    string LastName,
    string Login,
    PositionModel Position)
{
    private string? _fullName;
    public string FullName => _fullName ??= this.GetFullName();
}