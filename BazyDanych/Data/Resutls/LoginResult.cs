namespace BazyDanych.Data.Resutls;

public class LoginResult
{
    public bool Succeeded { get; private set; }

    public static LoginResult Success { get; } = new() { Succeeded = true };

    public static LoginResult Failed { get; } = new();
    
    public override string ToString() => Succeeded ? "Succeeded" : "Failed";
}