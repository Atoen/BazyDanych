using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics;

namespace BazyDanych.Data.Entities;

[DebuggerDisplay("{Name}, Salary = {Salary} PLN, Permissions ID = {PermissionsId}")]
public class Position
{
    [Column("id_stanowiska")] public int Id { get; set; }

    [Column("nazwa")] public string Name { get; set; } = null!;

    [Column("zarobki")] public decimal Salary { get; set; }

    [Column("id_uprawnien")] public int PermissionsId { get; set; }
}
