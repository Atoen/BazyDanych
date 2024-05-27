using BazyDanych.Extensions;

namespace BazyDanych.Data.Models;

public class EmployeeModel(
    int id,
    string firstName,
    string? secondName,
    string lastName,
    string login,
    string password,
    PositionModel position)
{
    private string? _fullName;
    public string FullName => _fullName ??= this.GetFullName();

    public int Id { get; set; } = id;
    public string FirstName { get; set; } = firstName;
    public string? SecondName { get; set; } = secondName;
    public string LastName { get; set; } = lastName;
    public string Login { get; set; } = login;
    public string Password { get; set; } = password;
    public PositionModel Position { get; set; } = position;
}