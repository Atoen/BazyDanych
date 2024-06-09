using System.Security.Cryptography;
using System.Text;

namespace BazyDanych.Services;

public class PasswordHasher
{
    public string HashPassword(string password)
    {
        var passwordBytes = Encoding.UTF8.GetBytes(password);
        return Convert.ToBase64String(SHA256.HashData(passwordBytes));
    }
}