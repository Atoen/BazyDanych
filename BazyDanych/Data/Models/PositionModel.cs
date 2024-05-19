namespace BazyDanych.Data.Models;

public class PositionModel(string name, PermissionsModel permissions)
{
    public string Name { get; } = name;
    public PermissionsModel Permissions { get; } = permissions;
}