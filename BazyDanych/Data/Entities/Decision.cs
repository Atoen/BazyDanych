using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics;

namespace BazyDanych.Data.Entities;

[DebuggerDisplay("Decision ID = {Id}, Employee ID = {EmployeeId}")]
public class Decision
{
    [Column("id_decyji")] public int Id { get; set; }

    [Column("id_pracownika_decydujacego")] public int EmployeeId { get; set; }
}