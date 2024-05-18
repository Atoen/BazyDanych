using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics;

namespace BazyDanych.Data.Entities;

[DebuggerDisplay("{FirstName} {LastName}, Position ID = {PositionId}, Login = {Login}")]
public class Employee
{
    [Column("id_pracownika")] public int Id { get; set; }

    [Column("id_stanowiska")] public int PositionId { get; set; }

    [Column("imie")] public string FirstName { get; set; } = null!;

    [Column("drugie_imie")] public string? MiddleName { get; set; }

    [Column("nazwisko")] public string LastName { get; set; } = null!;

    [Column("login")] public string Login { get; set; } = null!;

    [Column("haslo")] public string Password { get; set; } = null!;
}