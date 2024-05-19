namespace BazyDanych.Data.Models;

public class PermissionsModel(string permissions)
{
    public string Permissions { get; } = permissions;

    public override string ToString() => Permissions;
}