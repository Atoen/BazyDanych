using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics;

namespace BazyDanych.Data.Entities;

[DebuggerDisplay("{Name}, {Category}, {Price}PLN")]
public class Product
{
    [Column("id_produktu")] public int Id { get; set; }

    [Column("cena")] public decimal Price { get; set; }

    [Column("popularnosc")] public float Popularity { get; set; }

    [Column("dostepna_ilosc")] public int AvailableQuantity { get; set; }

    [Column("nazwa")] public string Name { get; set; } = string.Empty;

    [Column("jednostka")] public string Unit { get; set; } = string.Empty;

    [Column("kategoria")] public string Category { get; set; } = string.Empty;

    [NotMapped] public string AutoCompleteListName => AvailableQuantity > 0 ? Name : $"{Name} - Brak na stanie";
}