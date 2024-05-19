using BazyDanych.Extensions;

namespace BazyDanych.Data.Models;

public class EmployeeModel(string firstName, string? secondName, string lastName, PositionModel position)
{
    public string FirstName { get; } = firstName;
    public string? SecondName { get; } = secondName;
    public string LastName { get; } = lastName;

    public PositionModel Position { get; } = position;

    private string? _fullName;
    public string FullName => _fullName ??= this.GetFullName();
}