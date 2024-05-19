using System.ComponentModel.DataAnnotations;

namespace BazyDanych.Data.Models;

public class UserCredentials
{
    [Required(ErrorMessage = "Username is required")]
    public string Username { get; set; } = default!;
    
    [Required(ErrorMessage = "Password is required")]
    public string Password { get; set; } = default!;
}