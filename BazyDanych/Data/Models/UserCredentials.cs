using System.ComponentModel.DataAnnotations;

namespace BazyDanych.Data.Models;

public class UserCredentials
{
    [Required(ErrorMessage = "Nazwa użytkownika jest wymagana")]
    public string Username { get; set; } = default!;
    
    [Required(ErrorMessage = "Hasło jest wymagane")]
    public string Password { get; set; } = default!;
}