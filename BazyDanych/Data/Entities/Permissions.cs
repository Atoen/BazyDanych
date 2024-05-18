using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics;

namespace BazyDanych.Data.Entities;

[DebuggerDisplay("Permissions = {Permission}")]
public class Permissions
{
    [Column("id_uprawnien")] public int Id { get; set; }

    [Column("uprawnienia")] public string Permission { get; set; } = null!;
}